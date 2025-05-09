defmodule Sala do
  def iniciar(nombre_sala) do
    spawn(fn -> loop(nombre_sala, []) end)
  end

  def loop(nombre_sala, usuarios) do
    receive do
      {:unir, usuario = %Usuario{}} ->
        Util.mostrar_mensaje("#{usuario.nombre} se ha unido a la sala #{nombre_sala}.")
        enviar_mensaje_a_todos(usuarios, "#{usuario.nombre} ha entrado a la sala.")
        :timer.sleep(500)
        loop(nombre_sala, [usuario | usuarios])

      {:mensaje_sala, de, mensaje} ->
        fecha_hora = DateTime.utc_now() |> Calendar.strftime("%H:%M")
        mensaje_completo = "[#{de}]: #{mensaje}"
        mensaje_con_fecha = "[#{fecha_hora}] #{mensaje_completo}"
        enviar_mensaje_a_todos(usuarios, mensaje_con_fecha)
        guardar_mensaje(nombre_sala, mensaje_con_fecha)
        :timer.sleep(200)
        loop(nombre_sala, usuarios)

      {:salir, usuario} ->
        nuevos = Enum.reject(usuarios, fn usr -> usr.pid == usuario.pid end)
        enviar_mensaje_a_todos(nuevos, "#{usuario.nombre} ha dejado la sala.")
        :timer.sleep(300)
        loop(nombre_sala, nuevos)
      end
    end

  defp enviar_mensaje_a_todos(usuarios, mensaje) do
    usuarios
    |> Enum.filter(fn %Usuario{pid: pid} -> Process.alive?(pid) end)
    |> Enum.each(fn %Usuario{pid: pid} ->
      send(pid, {:mensaje_nuevo, mensaje})
    end)
  end

  defp guardar_mensaje(nombre_sala, mensaje) do
    if File.write!("historial_#{nombre_sala}.txt") do
      File.write!("historial_#{nombre_sala}.txt", mensaje <> "\n", [:append])
    else
      File.write!("historial_#{nombre_sala}.txt", mensaje <> "\n")
    end
  end
end
