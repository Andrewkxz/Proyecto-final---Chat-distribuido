defmodule Main do
  def correr_servidor do
    Node.start(:"servidor@localhost")
    Node.set_cookie(:chat)
    Servidor.inicio()
  end

  def correr_cliente do
    Node.start(:"cliente@localhost")
    Node.set_cookie(:chat)
    Cliente.inicio()
end
end
