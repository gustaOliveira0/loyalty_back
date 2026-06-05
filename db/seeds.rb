# Seed de demonstração do MVP de cashback.
#
# Uso:
#   bin/rails db:seed                # cria a loja demo se não existir
#   SEED_RESET=1 bin/rails db:seed   # apaga a loja demo e popula do zero
#
# Login criado: demo@loja.local / senha123
#
# Para rodar via Docker:
#   docker compose -p loyalty_dev exec api bin/rails db:seed
#   docker compose -p loyalty_dev exec -e SEED_RESET=1 api bin/rails db:seed

STORE_EMAIL    = "demo@loja.local".freeze
STORE_PASSWORD = "senha123".freeze

if ENV["SEED_RESET"] == "1"
  puts "Resetando dados da loja demo (#{STORE_EMAIL})..."
  User.where(email: STORE_EMAIL).destroy_all
end

store = User.find_or_initialize_by(email: STORE_EMAIL)
if store.new_record?
  store.assign_attributes(
    name: "Loja Demo",
    password: STORE_PASSWORD,
    cashback_kind: "money",
    cashback_expires_in_days: 30,
    cashback_min_redeem: 10
  )
  store.save!
  puts "Loja demo criada."
else
  puts "Loja demo ja existe."
end

if store.products.any?
  puts "Loja ja tem produtos -- pulando seed. Use SEED_RESET=1 para refazer."
  exit
end

puts "Criando categorias..."
cat_padaria = store.categories.create!(name: "Padaria")
cat_bebidas = store.categories.create!(name: "Bebidas")
cat_lanches = store.categories.create!(name: "Lanches")
cat_doces   = store.categories.create!(name: "Confeitaria")

puts "Criando produtos..."
products_data = [
  { cat: cat_padaria, name: "Pao Frances (un)",        value:  1.20, mode: "percent", cb:  5 },
  { cat: cat_padaria, name: "Pao de Queijo",           value:  3.50, mode: "percent", cb: 10 },
  { cat: cat_padaria, name: "Pao de Forma",            value: 12.00, mode: "fixed",   cb:  1 },
  { cat: cat_bebidas, name: "Coca-Cola 350ml",         value:  6.00, mode: "percent", cb:  5 },
  { cat: cat_bebidas, name: "Suco de Laranja",         value:  8.00, mode: "percent", cb:  8 },
  { cat: cat_bebidas, name: "Cafe Espresso",           value:  5.00, mode: "fixed",   cb:  0.50 },
  { cat: cat_lanches, name: "Misto Quente",            value: 12.00, mode: "percent", cb: 10 },
  { cat: cat_lanches, name: "Coxinha",                 value:  7.00, mode: "fixed",   cb:  1 },
  { cat: cat_doces,   name: "Brigadeiro",              value:  4.00, mode: "fixed",   cb:  0.40 },
  { cat: cat_doces,   name: "Bolo de Cenoura (fatia)", value:  8.00, mode: "percent", cb: 12 }
]
products = products_data.map do |p|
  store.products.create!(
    category: p[:cat], name: p[:name], value: p[:value],
    cashback_mode: p[:mode], cashback_value: p[:cb]
  )
end

puts "Criando clientes..."
customers_data = [
  { name: "Joana Souza",      cpf: "11122233300", phone: "11988887701", birth: "1990-05-12" },
  { name: "Carlos Lima",      cpf: "22233344411", phone: "11988887702", birth: "1985-09-23" },
  { name: "Beatriz Santos",   cpf: "33344455522", phone: "11988887703", birth: "1995-02-08" },
  { name: "Ricardo Oliveira", cpf: "44455566633", phone: "11988887704", birth: "1978-11-17", opt_in: false },
  { name: "Fernanda Costa",   cpf: "55566677744", phone: "11988887705", birth: "2000-07-30" },
  { name: "Lucas Pereira",    cpf: "66677788855", phone: "11988887706", birth: "1992-03-14" }
]
customers = customers_data.map do |c|
  store.customers.create!(
    name: c[:name], cpf: c[:cpf], phone_number: c[:phone],
    birth_date: c[:birth], whatsapp_opt_in: c.fetch(:opt_in, true)
  )
end

puts "Criando vendas historicas (com cashback)..."
# Seed deterministico para o historico ser reproduzivel.
rng = Random.new(42)
days_ago = [30, 28, 25, 22, 20, 18, 15, 14, 12, 10, 9, 7, 6, 5, 3, 2, 1, 0]
days_ago.each do |dago|
  customer = customers.sample(random: rng)
  items_n  = 1 + rng.rand(3)
  items    = items_n.times.map do
    product = products.sample(random: rng)
    { product_id: product.id, quantity: 1 + rng.rand(3) }
  end
  CashbackService.record_sale(
    user: store, customer: customer, items: items,
    sale_date: dago.days.ago, notify: false
  )
end

puts "Registrando 1 resgate de exemplo..."
top_customer = customers.max_by(&:balance)
if top_customer && top_customer.balance >= store.cashback_min_redeem
  CashbackService.redeem(
    customer: top_customer,
    amount: store.cashback_min_redeem,
    description: "Resgate de exemplo (seed)"
  )
end

puts "Criando mensagens de exemplo (aba 'Mensagens enviadas')..."
sample = customers.first
sample.message_deliveries.create!(
  channel: "whatsapp", template: "cashback_received", status: "sent",
  body: "Oi #{sample.name.split.first}! Voce acabou de ganhar R$ 4,50 de cashback em #{store.name}. Use ate #{30.days.from_now.strftime('%d/%m/%Y')}.",
  sent_at: 3.days.ago, created_at: 3.days.ago
)
sample.message_deliveries.create!(
  channel: "whatsapp", template: "cashback_expiring", status: "sent",
  body: "Oi #{sample.name.split.first}, seu cashback de R$ 4,50 em #{store.name} expira em #{5.days.from_now.strftime('%d/%m/%Y')}. Aproveite antes que venca!",
  sent_at: 1.day.ago, created_at: 1.day.ago
)

puts "Criando colaboradores fictícios..."
collaborators_data = [
  {
    name: "Ana Paula Mendes",
    cpf: "98765432100",
    birth_date: "1992-03-18",
    email: "ana.colaboradora@demo.local",
    password: "senha123",
    can_edit_customers: true, can_delete_customers: false,
    can_create_sales: true,   can_manage_products: false,
    can_manage_categories: false, can_manage_credit_rules: false,
    can_view_dashboard: true, can_manage_settings: false
  },
  {
    name: "Bruno Carvalho",
    cpf: "12312312312",
    birth_date: "1988-07-22",
    email: "bruno.colaborador@demo.local",
    password: "senha123",
    can_edit_customers: true, can_delete_customers: true,
    can_create_sales: true,   can_manage_products: true,
    can_manage_categories: true, can_manage_credit_rules: false,
    can_view_dashboard: true, can_manage_settings: false,
    active: false
  },
  {
    name: "Camila Torres",
    cpf: "32132132132",
    birth_date: "1995-11-05",
    email: "camila.colaboradora@demo.local",
    password: "senha123",
    can_edit_customers: false, can_delete_customers: false,
    can_create_sales: true,    can_manage_products: false,
    can_manage_categories: false, can_manage_credit_rules: false,
    can_view_dashboard: false, can_manage_settings: false
  }
]

collaborators_data.each do |c|
  next if store.collaborators.exists?(email: c[:email])
  store.collaborators.create!(
    name: c[:name], cpf: c[:cpf], birth_date: c[:birth_date],
    email: c[:email], password: c[:password],
    can_edit_customers: c[:can_edit_customers],
    can_delete_customers: c[:can_delete_customers],
    can_create_sales: c[:can_create_sales],
    can_manage_products: c[:can_manage_products],
    can_manage_categories: c[:can_manage_categories],
    can_manage_credit_rules: c[:can_manage_credit_rules],
    can_view_dashboard: c[:can_view_dashboard],
    can_manage_settings: c[:can_manage_settings],
    active: c.fetch(:active, true)
  )
  puts "  Colaborador: #{c[:name]} (#{c[:email]})"
end

puts
puts "=" * 60
puts "Seed concluido!"
puts "  Login: #{STORE_EMAIL}"
puts "  Senha: #{STORE_PASSWORD}"
puts "  Loja:  #{store.name} (cashback em #{store.cashback_kind})"
puts "  Categorias: #{store.categories.count}"
puts "  Produtos:   #{store.products.count}"
puts "  Clientes:   #{store.customers.count}"
puts "  Vendas:     #{store.sales.count}"
puts "  Saldo total dos clientes: R$ #{customers.sum(&:balance).round(2)}"
puts "=" * 60
