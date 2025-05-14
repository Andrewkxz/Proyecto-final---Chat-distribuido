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
    ingresar(mensaje, &String.to_integer/1, :entero)
  end

  def ingresar(mensaje, :boolean) do
    valor =
      mensaje
      |> ingresar(:texto)
      |> String.downcase()

    Enum.member?(["s", "si", "sí"], valor)
  end

  def ingresar(mensaje, :real) do
    ingresar(mensaje, &String.to_float/1, :real)
  end

  def ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        mostrar_error("Error, se espera que ingrese un número #{tipo_dato}")
        ingresar(mensaje, parser, tipo_dato)
    end
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  def cifrar_mensaje(mensaje) do
    Base.encode64(mensaje)
  end

  def descifrar_mensaje(mensaje_cifrado) do
    case Base.decode64(mensaje_cifrado) do
      {:ok, mensaje} -> mensaje
      :error -> mensaje_cifrado
    end
  end
end
