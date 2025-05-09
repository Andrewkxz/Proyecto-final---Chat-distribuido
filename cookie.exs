defmodule Cookie do
  @longitud_llave 10

  def main() do
    :crypto.strong_rand_bytes(@longitud_llave)
    |> Base.encode64()
    |> Util.mostrar_mensaje()
  end
end

Cookie.main()
