defmodule Util do

  def add_mensaje(sala, usuario, texto) do
    File.write!("#{sala}_historial.txt", "#{usuario}: #{texto}\n", [:append])
  end

  def cargar_historial(sala) do
    case File.read("#{sala}_historial.txt") do
      {:ok, contenido} -> contenido
      _ -> "No hay historial disponible."
    end
  end
end
