defmodule Usuario do
  defstruct nombre: "", contrasena: "", pid: nil

  @usuarios "usuarios.txt"

  def autenticar() do
    nombre = Util.ingresar("Ingrese su nombre: ", :texto)
    contrasena = Util.ingresar("Contraseña: ", :texto)

    case buscar_usuario(nombre) do
      {:ok, contrasena_guardada} ->
        if contrasena_guardada == contrasena do
          Util.mostrar_mensaje("Autenticación exitosa")
          :timer.sleep(500)
          %Usuario{nombre: nombre, contrasena: contrasena, pid: self()}
        else
          Util.mostrar_error("Contraseña incorrecta")
          autenticar()
        end

      :error ->
        Util.mostrar_mensaje("Registrando usuario nuevo...")
        registrar_usuario(nombre, contrasena)
        %Usuario{nombre: nombre, contrasena: contrasena, pid: self()}
    end
  end

  defp buscar_usuario(nombre) do
    if File.exists?(@usuarios) do
      File.stream!(@usuarios)
      |> Enum.find_value(:error, fn linea ->
        case String.split(String.trim(linea), ":") do
          [nombre_guardado, contrasena_guardada] when nombre_guardado == nombre ->
            {:ok, contrasena_guardada}
          _ ->
            nil
        end
      end)
    else
      :error
    end
  end

  defp registrar_usuario(nombre, contrasena) do
    File.write!(@usuarios, "#{nombre}:#{contrasena}\n", [:append])
    Util.mostrar_mensaje("Usuario registrado con éxito")
  end

  def cargar_usuarios() do
    if File.exists?(@usuarios) do
      File.stream!(@usuarios)
      |> Enum.reduce(%{}, fn linea, acc ->
        case String.split(String.trim(linea), ":") do
          [nombre, contrasena] ->
            Map.put(acc, nombre, %Usuario{nombre: nombre, contrasena: contrasena, pid: nil})

          _ ->
            acc
        end
      end)
    else
      %{}
    end
  end
end
