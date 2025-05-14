@moduledoc """
  Módulo Supervisor que se encarga de reiniciar el servidor en caso de que muera.
  Este módulo utiliza el patrón de supervisión para garantizar que el servidor esté siempre en ejecución.
  """
defmodule Supervisor do
  # Este módulo es responsable de supervisar el servidor y reiniciarlo en caso de que falle.
  def iniciarSupervisor do
    # Procesa la señal de salida del servidor y reinicia el servidor en caso de que muera.
    # Se utiliza el flag :trap_exit para recibir mensajes de salida de procesos hijos.
    Process.flag(:trap_exit, true)
    # Inicia el servidor de forma asíncrona y lo vincula al supervisor.
    # Se utiliza spawn_link para crear un nuevo proceso y vincularlo al supervisor.
    spawn_link(fn -> iniciar_servidor() end)
    loop()
  end

  # Este es el bucle principal del supervisor.
  # Maneja la recepción de mensajes de salida del servidor y reinicia el servidor en caso de que muera.
  defp iniciar_servidor do
    # Inicia el servidor de forma asíncrona y lo vincula al supervisor.
    # Se utiliza spawn_link para crear un nuevo proceso y vincularlo al supervisor.
    # Se utiliza NodoServidor.main() para iniciar el servidor.
  spawn_link(fn -> NodoServidor.main() end)
  end

  # Este es el bucle principal del supervisor.
  defp loop do
    receive do
      {:EXIT, _pid, motivo} ->
        # Maneja la señal de salida del servidor.
        # Loguea el motivo de la muerte del servidor y reinicia el servidor.
        log_evento("El servidor murió por el siguiente motivo: #{motivo}. Reiniciando...")
        # Inicia el servidor de forma asíncrona y lo vincula al supervisor.
        iniciar_servidor()
        # Vuelve a llamar al bucle para seguir supervisando el servidor.
        loop()
      end
    end

    # Función para loguear eventos en un archivo de texto (log.txt).
    defp log_evento(mensaje) do
      # Abre el archivo log.txt en modo de escritura y agrega el mensaje al final del archivo.
      # Se utiliza File.write! para escribir el mensaje en el archivo.
      # Se utiliza [:append] para agregar el mensaje al final del archivo sin sobrescribirlo.
      # Se utiliza el operador <> para concatenar el mensaje con un salto de línea.
      File.write!("log.txt", "[#{DateTime.utc_now()}] #{mensaje}\n", [:append])
    end
  end

# Inicia el supervisor.
  Supervisor.iniciarSupervisor()
