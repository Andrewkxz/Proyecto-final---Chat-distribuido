# Este script genera una cookie segura aleatoriamente y la imprime en la consola.
defmodule Cookie do

  #atributo para especificar la longitud en bytes de la llave aleatoria a generar
  @longitud_llave 10

  def main() do
    #genera cookies seguras
    :crypto.strong_rand_bytes(@longitud_llave)

    #esa cadena se codifica a texto base64
    |> Base.encode64()

    #se imprime la cadena en la consola
    |> Util.mostrar_mensaje()
  end
end

#genera e imprime una cookie segura aleatoriamente
Cookie.main()
