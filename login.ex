defmodule Autenticarse do
  def autenticacion(nombre_usuario, contrasena) do
    case File.read("usuarios.txt") do
      {ok, contenido} ->
        if Enum.any?(String.split(contenido, "\n"), fn linea -> linea == "#{nombre_usuario}:#{contrasena}" end) do
          :ok
        else
          {:error, "Usuario o contraseña incorrectos"}
        end

        _-> {:error, "No se pudo leer el archivo"}
      end
    end


  def registro_usuario(nombre_usuario, contrasena) do
    case File.read("usuarios.txt") do
      {:ok, contenido} ->
        if String.contains?(contenido, "#{nombre_usuario}") do
          {:error, "El usuario ya existe"}
        else
          File.write!("usuarios.txt", <> "\n#{nombre_usuario}:#{contrasena}")
          :ok
      end
      {:error, _} ->
        File.write!("usuarios.txt", "#{nombre_usuario}:#{contrasena}\n")
        :ok
    end
  end
end
