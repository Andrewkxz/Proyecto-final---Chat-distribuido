defmodule Util do

  def guardar_mensaje(nombre_sala, mensaje) do
    File.write!("#{nombre_sala}_historial.txt", mensaje <> "\n", [:append])
  end

  def cargar_historial(nombre_sala) do
    case File.read("#{nombre_sala}_historial.txt") do
      {:ok, contenido} -> String.split(contenido, "\n") |> Enum.join("\n")
      _ -> "No hay historial disponible."
    end
  end
end
