defmodule Sala do
  def iniciar(nombre_sala) do
    spawn(fn -> loop(nombre_sala, []) end)
  end

  def loop(nombre_sala, usuarios) do
    receive do
      {:unir, usuario = %Usuario{}} ->
        # Verifica si el usuario ya estaba en la sala
        usuarios_actualizados = usuarios
        |> Enum.reject(fn u -> u.nombre == usuario.nombre end)
        |> Kernel.++([%{usuario | pid: usuario.pid}])

        Util.mostrar_mensaje("#{usuario.nombre} se ha unido a la sala #{nombre_sala}.")
        enviar_mensaje_a_todos(usuarios_actualizados, "[INFO] #{usuario.nombre} ha entrado a la sala.")
        :timer.sleep(500)
        loop(nombre_sala, usuarios_actualizados)

      {:mensaje_sala, de, mensaje} ->
        fecha_hora = DateTime.utc_now() |> Calendar.strftime("%H:%M")
        mensaje_con_fecha = "[#{fecha_hora}] #{de}: #{mensaje}"
        enviar_mensaje_a_todos(usuarios, mensaje_con_fecha)
        guardar_mensaje(nombre_sala, mensaje_con_fecha)
        :timer.sleep(200)
        loop(nombre_sala, usuarios)

      {:salir, usuario} ->
        nuevos = Enum.reject(usuarios, fn usr -> usr.nombre == usuario.nombre end)
        enviar_mensaje_a_todos(nuevos, "[INFO] #{usuario.nombre} ha salido de la sala.")
        :timer.sleep(300)
        loop(nombre_sala, nuevos)
    end
  end

  defp enviar_mensaje_a_todos(usuarios, mensaje) do
    Enum.each(usuarios, fn %Usuario{pid: pid} ->
      send(pid, {:mensaje_nuevo, mensaje})
    end)
  end

  defp guardar_mensaje(nombre_sala, mensaje) do
    File.write!("historial_#{nombre_sala}.txt", mensaje <> "\n", [:append])
  end
end
