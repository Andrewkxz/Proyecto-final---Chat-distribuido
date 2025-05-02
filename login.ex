defmodule Autenticarse do
  def autenticacion(nombre_usuario, contrasena) do
    case.File.read("usuarios.txt") do
      {ok, contenido} ->
        contenido
          |> String.split("\n", trim:true)
          |> Enum.any?(fn linea ->
            linea == "#{nombre_usuario}:#{contrasena}"
          end)

      _ ->
        IO.puts("Error al leer el archivo de usuarios.")
        false
    end
  end

  def registro_usuario(nombre_usuario, contrasena) do
    if autenticacion(nombre_usuario, contrasena) do
      {:error, :usuario_existente}
    else
      File.write!("usuarios.txt", "#{nombre_usuario}:#{contrasena}\n", [:append])
      {:ok, :usuario_registrado}
    end
  end
end
