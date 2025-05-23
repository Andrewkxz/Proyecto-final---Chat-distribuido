defmodule Util do
  def mostrar_mensaje(mensaje) do
    IO.puts("#{mensaje}")
  end

  def ingresar(mensaje, :texto) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def ingresar(mensaje, :entero) do
    ingresar(
      mensaje,
      &String.to_integer/1,
      :entero
      )
  end

  def ingresar(mensaje, :boolean) do
    valor =
      mensaje
      |> ingresar(:texto)
      |> String.downcase()

    Enum.member?(["s", "si", "sí"], valor)
  end

  def ingresar(mensaje, :real) do
    ingresar(
      mensaje,
      &String.to_float/1,
      :real
      )
  end

  def ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un numero #{tipo_dato}\n"
        |> mostrar_error()

        mensaje
        |> ingresar(parser, tipo_dato)

    end
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  def cifrar_mensaje(mensaje, clave \\ 3) do
    mensaje
    |> String.to_charlist()
    |> Enum.map(&rem(&1 + clave, 256))
    |> to_string()
  end

  def descifrar_mensaje(mensaje, clave \\ 3) do
    mensaje
    |> String.to_charlist()
    |> Enum.map(&rem(&1 - clave + 256, 256))
    |> to_string()
  end
end
