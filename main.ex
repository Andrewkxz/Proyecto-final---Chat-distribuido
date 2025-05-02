defmodule Main do
  def correr do
    servidor = Servidor.start_link()
    spawn(fn -> Cliente.start_link(servidor) end)
  end
end
