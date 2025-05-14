@moduledoc """
  Módulo principal del servidor que maneja la lógica de autenticación y gestión de salas.
  """
defmodule Sala do
  # Este módulo representa una sala de chat y maneja la lógica de unión, envío de mensajes y salida de usuarios.
  def iniciar(nombre_sala) do
    # Inicia el servidor de la sala con el nombre proporcionado.
    # El nombre de la sala se utiliza para identificar el archivo de historial.
    spawn(fn -> loop(nombre_sala, [], []) end)
  end

  # Este es el bucle principal del servidor de la sala.
  # Maneja la recepción de mensajes y la lógica de unión, envío de mensajes y salida de usuarios.
  def loop(nombre_sala, usuarios, mensajes) do
    receive do

      # Recibe un mensaje de unión de un usuario.
      {:unir, usuario = %Usuario{}} ->
        # Evita duplicados del mismo usuario
        usuarios_actualizados = usuarios
        |> Enum.reject(fn %Usuario{nombre: nombre} -> nombre == usuario.nombre end)
        |> Kernel.++([usuario]) # Asegura que siga siendo %Usuario{}

        # Muestra un mensaje de unión del usuario en la consola.
        Util.mostrar_mensaje("#{usuario.nombre} se ha unido a la sala #{nombre_sala}.")
        # Envía un mensaje a todos los usuarios de la sala.
        enviar_mensaje_a_todos(usuarios_actualizados, "[INFO] #{usuario.nombre} ha entrado a la sala.")
        # Envía el historial de mensajes al nuevo usuario.
        enviar_historial(usuario.pid, mensajes)
        # Pausa el proceso durante 500 ms para evitar la saturación de mensajes.
        :timer.sleep(500)
        # Vuelve a llamar al bucle con la lista de usuarios actualizada.
        loop(nombre_sala, usuarios_actualizados, mensajes)

      # Recibe un mensaje de un usuario.
      {:mensaje_sala, de, mensaje} ->
        # Obtiene la fecha y hora actual en la zona horaria de Colombia (UTC-5).
        # Se resta 5 horas para ajustar a la zona horaria de Colombia.
        # Se utiliza DateTime.utc_now() para obtener la fecha y hora actual en UTC.
        # Se utiliza DateTime.add(-5 * 3600, :second) para ajustar a la zona horaria de Colombia.
        # Se utiliza Calendar.strftime para formatear la fecha y hora en el formato deseado.
        # Se utiliza String.downcase() para convertir a minúsculas.
        # Se utiliza String.replace() para reemplazar "am" por "a.m." y "pm" por "p.m.".
        hora_colombia = DateTime.utc_now() |> DateTime.add(-5 * 3600, :second)
        fecha_hora = Calendar.strftime(hora_colombia, "%I:%M %p")
        |> String.downcase()
        |> String.replace("am", "a.m.")
        |> String.replace("pm", "p.m.")
        # Se crea un nuevo mensaje con la fecha y hora actual.
        mensaje_con_fecha = "[#{fecha_hora}] #{de}: #{mensaje}"
        # Se muestra el mensaje en la consola.
        mensajes_actualizados = mensajes ++ [mensaje_con_fecha]
        # Se envía el mensaje a todos los usuarios de la sala.
        enviar_mensaje_a_todos(usuarios, mensaje_con_fecha)
        # Se guarda el mensaje en el archivo de historial de la sala.
        guardar_mensaje(nombre_sala, mensaje_con_fecha)
        # Pausa el proceso durante 200 ms para evitar la saturación de mensajes.
        :timer.sleep(200)
        # Vuelve a llamar al bucle con la lista de usuarios y mensajes actualizados.
        loop(nombre_sala, usuarios, mensajes_actualizados)

      # Recibe un mensaje de salida de un usuario.
      {:salir, %Usuario{nombre: nombre_usuario} = usuario} ->
        # Verifica si el usuario está en la sala.
        nuevos_usuarios = Enum.reject(usuarios, fn %Usuario{nombre: nombre} -> nombre == nombre_usuario end)
        # Si el usuario está en la sala, se muestra un mensaje de salida en la consola.
        IO.puts("El usuario #{nombre_usuario} ha salido de la sala.")
        # Se envía un mensaje a todos los usuarios de la sala.
        enviar_mensaje_a_todos(nuevos_usuarios, "[INFO] #{nombre_usuario} ha salido de la sala.")
        # Se guarda el mensaje de salida en el archivo de historial de la sala.
        send(usuario.pid, {:salida_sala, nombre_sala})
        # Se pausa el proceso durante 300 ms para evitar la saturación de mensajes.
        :timer.sleep(300)
        # vuelve a llamar al bucle con la lista de usuarios actualizada.
        loop(nombre_sala, nuevos_usuarios, mensajes)

    end
  end

  # función privada para enviar un mensaje a todos los usuarios de la sala.
  defp enviar_mensaje_a_todos(usuarios, mensaje) do
    # Se utiliza Enum.each para iterar sobre la lista de usuarios.
    Enum.each(usuarios, fn %Usuario{pid: pid} ->
      # Se envía el mensaje a cada usuario.
      send(pid, {:mensaje_nuevo, mensaje})
    end)
  end

  # función privada para guardar un mensaje en el archivo de historial de la sala.
  defp guardar_mensaje(nombre_sala, mensaje) do
    # Se utiliza File.write! para escribir el mensaje en el archivo de historial.
    # Se utiliza [:append] para agregar el mensaje al final del archivo.
    # Se utiliza el operador <> para concatenar el mensaje con un salto de línea.
    File.write!("historial_#{nombre_sala}.txt", mensaje <> "\n", [:append])
  end

  # función privada para enviar el historial de mensajes a un usuario.
  defp enviar_historial(pid, mensajes) do
    # Se utiliza Enum.each para iterar sobre la lista de mensajes.
    Enum.each(mensajes, fn mensaje ->
      # Se envía el mensaje al usuario.
      # Se utiliza el operador send para enviar el mensaje al proceso del usuario.
      send(pid, {:mensaje_nuevo, mensaje})
    end)
  end
end
