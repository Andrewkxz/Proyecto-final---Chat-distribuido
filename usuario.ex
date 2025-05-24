defmodule Usuario do
  defstruct nombre: "", pid: nil, contrasena: ""

  @usuarios "usuarios.csv"

  # Crea un struct de Usuario
  def crear(nombre, contrasena) do
    %Usuario{nombre: nombre, pid: self(), contrasena: contrasena}
  end

  # Autenticación de usuario
  def autenticar() do
    nombre = "Ingrese su nombre de usuario: "
    |> Util.ingresar(:texto)

    contrasena = "Ingrese su contraseña: "
    |> Util.ingresar(:texto)

    case buscar_usuario(nombre) do
      {:ok, contrasena_guardada} ->
        if contrasena_guardada == contrasena do
          Util.mostrar_mensaje("Autenticación exitosa")
          :timer.sleep(500)
          crear(nombre, contrasena)
        else
          Util.mostrar_mensaje("Contraseña incorrecta")
          autenticar()
        end

      :error ->
        Util.mostrar_mensaje("Registrando usuario...")
        registrar_usuario(nombre, contrasena)
        crear(nombre, contrasena)
    end
  end

  # Buscar un usuario por nombre en el CSV
  defp buscar_usuario(nombre) do
    if File.exists?(@usuarios) do
      File.stream!(@usuarios)
      |> Stream.drop(1) # Ignorar encabezado
      |> Enum.find_value(:error, fn linea ->
        case String.split(String.trim(linea), ",") do
          [nombre_guardado, contrasena_guardada] when nombre_guardado == nombre ->
            {:ok, contrasena_guardada}
          _ -> nil
        end
      end)
    else
      :error
    end
  end

  # Registrar usuario nuevo en el CSV
  defp registrar_usuario(nombre, contrasena) do
    # Si el archivo no existe, escribir encabezado primero
    unless File.exists?(@usuarios) do
      File.write!(@usuarios, "nombre,contrasena\n")
    end

    File.write!(@usuarios, "#{nombre},#{contrasena}\n", [:append])
    Util.mostrar_mensaje("Usuario registrado con éxito")
  end

  # Cargar todos los usuarios del archivo CSV en un mapa
  def cargar_usuarios() do
    if File.exists?(@usuarios) do
      File.stream!(@usuarios)
      |> Stream.drop(1) # Ignorar encabezado
      |> Enum.reduce(%{}, fn linea, acc ->
        case String.split(String.trim(linea), ",") do
          [nombre, contrasena] ->
            Map.put(acc, nombre, %Usuario{nombre: nombre, pid: nil, contrasena: contrasena})
          _ -> acc
        end
      end)
    else
      %{}
    end
  end

  # Leer CSV desde ruta externa y convertirlo en lista de structs
  def leer_csv(ruta) do
    ruta
    |> File.stream!()
    |> Stream.drop(1) # Ignorar encabezado
    |> Enum.map(&convertir_cadena_cliente/1)
  end

  defp convertir_cadena_cliente(cadena) do
    [nombre, contrasena] =
      cadena
      |> String.trim()
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    crear(nombre, contrasena)
  end
end
