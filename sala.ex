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
        enviar_a_todos(usuarios, "[#{de}]: #{mensaje}")
        :timer.sleep(200)
        loop(nombre_sala, usuarios)

      {:salir, usuario} ->
        nuevos = Enum.reject(usuarios, fn usr -> usr.pid == usuario.pid end)
        enviar_a_todos(nuevos, "#{usuario.nombre} ha dejado la sala.")
        :timer.sleep(300)
        loop(nombre_sala, nuevos)
      end
    end

    defp enviar_a_todos(usuarios, mensaje) do
      Enum.each(usuarios, fn %Usuario{pid: pid} ->
        send(pid, {:mensaje_nuevo, mensaje}) end)
      end
    end
