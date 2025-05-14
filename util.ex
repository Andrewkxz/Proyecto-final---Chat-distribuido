@moduledoc """
  Moduulo Util que contiene funciones de utilidad para el servidor.
  Este modulo incluye funciones para mostrar mensajes, ingresar datos, cifrar y descifrar mensajes.
  """
defmodule Util do
  # Función para mostrar un mensaje en la consola.
  def mostrar_mensaje(mensaje) do
    # Se utiliza IO.puts para imprimir el mensaje en la consola.
    IO.puts("#{mensaje}")
  end

  # Función para ingresar datos de texto desde la consola.
  def ingresar(mensaje, :texto) do
    mensaje
    # Se utiliza IO.gets para leer la entrada del usuario.
    # Se utiliza String.trim para eliminar los espacios en blanco al principio y al final de la cadena.
    |> IO.gets()
    |> String.trim()
  end

  # Función para ingresar datos de tipo entero desde la consola.
  def ingresar(mensaje, :entero) do
    # Se utiliza la función ingresar para leer la entrada del usuario como texto.
    ingresar(
      mensaje,
      # Se utiliza String.to_integer para convertir la cadena de texto a un número entero.
      # Se utiliza la función & para crear una función anónima que llama a String.to_integer.
      &String.to_integer/1,
      # Se especifica el tipo de dato como :entero.
      :entero
      )
  end

  # Función para ingresar datos de tipo booleano desde la consola.
  def ingresar(mensaje, :boolean) do
    # Se utiliza la función ingresar para leer la entrada del usuario como texto.
    valor =
      mensaje
      # Se utiliza la función ingresar para leer la entrada del usuario como texto.
      # Se utiliza String.downcase para convertir la cadena de texto a minúsculas.
      |> ingresar(:texto)
      |> String.downcase()

    # Se utiliza Enum.member? para verificar si el valor ingresado es uno de los valores válidos.
    Enum.member?(["s", "si", "sí"], valor)
  end

  # Función para ingresar datos de tipo real desde la consola.
  def ingresar(mensaje, :real) do
    # Se utiliza la función ingresar para leer la entrada del usuario como texto.
    ingresar(
      mensaje,
      # Se utiliza String.to_float para convertir la cadena de texto a un número real.
      # Se utiliza la función & para crear una función anónima que llama a String.to_float.
      &String.to_float/1,
      # Se especifica el tipo de dato como :real.
      :real
      )
  end

  # Función para ingresar datos de tipo entero desde la consola.
  # Esta función se utiliza para manejar la entrada de datos y convertirlos al tipo de dato especificado.
  # Se utiliza la función ingresar para leer la entrada del usuario como texto.
  def ingresar(mensaje, parser, tipo_dato) do
    # Se utiliza try para manejar excepciones.
    try do
      mensaje
      # Se utiliza la función ingresar para leer la entrada del usuario como texto.
      # Se utiliza parser para convertir la cadena de texto al tipo de dato especificado.
      |> ingresar(:texto)
      |> parser.()
      # Se utiliza rescue para manejar excepciones.
    rescue
      # Se utiliza ArgumentError para manejar errores de conversión.
      ArgumentError ->
        # Se utiliza IO.puts para imprimir un mensaje de error en la consola.
        "Error, se espera que ingrese un numero #{tipo_dato}\n"
        # Se utiliza mostrar_error para mostrar el mensaje de error en la consola.
        |> mostrar_error()

        # Se utiliza la función ingresar para volver a solicitar la entrada del usuario.
        mensaje
        |> ingresar(parser, tipo_dato)

    end
  end

  # Función para mostrar un mensaje de error en la consola.
  def mostrar_error(mensaje) do
    # Se utiliza IO.puts para imprimir el mensaje de error en la consola.
    # Se utiliza el módulo :standard_error para imprimir el mensaje en la consola de errores.
    IO.puts(:standard_error, mensaje)
  end

  # Función para cifrar un mensaje utilizando una clave.
  # Esta función utiliza un algoritmo de cifrado simple para cifrar el mensaje.
  def cifrar_mensaje(mensaje, clave \\ 3) do
    mensaje
    # Se utiliza String.to_charlist para convertir la cadena de texto a una lista de caracteres.
    |> String.to_charlist()
    # Se utiliza Enum.map para aplicar la función de cifrado a cada carácter de la lista.
    # Se utiliza rem para aplicar la operación de módulo a cada carácter.
    # Se utiliza la clave para cifrar el mensaje.
    # Se utiliza 256 para asegurarse de que el resultado esté dentro del rango de caracteres ASCII.
    |> Enum.map(&rem(&1 + clave, 256))
    # Se utiliza to_string para convertir la lista de caracteres cifrados de nuevo a una cadena de texto.
    |> to_string()
  end

  # Función para descifrar un mensaje utilizando una clave.
  # Esta función utiliza el mismo algoritmo de cifrado para descifrar el mensaje.
  def descifrar_mensaje(mensaje, clave \\ 3) do
    mensaje
    # Se utiliza String.to_charlist para convertir la cadena de texto a una lista de caracteres.
    |> String.to_charlist()
    # Se utiliza Enum.map para aplicar la función de descifrado a cada carácter de la lista.
    # Se utiliza rem para aplicar la operación de módulo a cada carácter.
    # Se utiliza la clave para descifrar el mensaje.
    # Se utiliza 256 para asegurarse de que el resultado esté dentro del rango de caracteres ASCII.
    |> Enum.map(&rem(&1 - clave + 256, 256))
    # Se utiliza to_string para convertir la lista de caracteres descifrados de nuevo a una cadena de texto.
    |> to_string()
  end
end
