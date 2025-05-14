defmodule Usuario do
  defstruct nombre: "", pid: nil, contrasena: nil
  @usuarios "usuarios.txt"

  def autenticar() do
    nombre = Util.ingresar("Ingrese su nombre: ", :texto)
    contrasena = Util.ingresar("Contraseña: ", :texto)

    case buscar_usuario(nombre) do
      {:ok, contrasena_guardada} ->
        if contrasena_guardada == contrasena do
          Util.mostrar_mensaje("Autenticación exitosa")
          :timer.sleep(500)
          %Usuario{nombre: nombre, pid: self()}
        else
          Util.mostrar_mensaje("Contraseña incorrecta")
          autenticar()
        end


      :error ->
        Util.mostrar_mensaje("Registrando usuario...")
        registrar_usuario(nombre, contrasena)
        %Usuario{nombre: nombre, pid: self()}
      end
    end

    defp buscar_usuario(nombre) do
      if File.exists?(@usuarios) do
        File.stream!(@usuarios)
        |> Enum.find_value(:error, fn linea ->
          case String.split(String.trim(linea), ":") do
            [nombre_guardado, contrasena_guardada] when nombre_guardado == nombre ->
              {:ok, contrasena_guardada}
            _ -> nil
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
          [nombre, contrasena] -> Map.put(acc, nombre, %Usuario{nombre: nombre, pid: nil, contrasena: contrasena})
          _ -> acc
        end
      end)
    else
      %{}
    end
  end
end
