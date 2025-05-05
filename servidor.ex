defmodule Servidor do
  def inicio do
    IO.puts("[Servidor] Iniciando servidor...")
    :global.registrar_nombre_servidor(:servidor, spawn_link(__MODULE__, :init, [%{usuarios: %{}, salas: %{}}]))
  end

  def init(estado), do
    IO.puts("[Servidor] Servidor creado con exito.")
    ciclo(estado)
  end

  defp ciclo(estado) do
    receive do
      {:registrar_usuario, nombre_usuario, contrasena, de} ->
        case Autenticacion.registrar_usuario(nombre_usuario, contrasena) do
          :ok -> send(de, {:ok, "Usuario registrado."})
          {:error, mensaje} -> send(de, {:error, mensaje})
        end
        :timer.sleep(200)
        ciclo(estado)

      {:ingresar, nombre_usuario, contrasena, de} ->
        case Autenticacion.iniciar_sesion(nombre_usuario, contrasena) do
          :ok -> send(de, {:ok, "Bienvenido #{nombre_usuario}"})
          {:error, mensaje} -> send(de, {:error, mensaje})
        end
        :timer.sleep(200)
        ciclo(estado)

      {:crear_sala, nombre_sala, de} ->
        estado_nuevo = if Map.has_key?(estado.salas, nombre_sala) do
          send(de, {:error, "La sala ya existe."})
          estado
          else
            send(de, {:ok, "Sala #{nombre_sala} creada exitosamente."})
            Map.update!(estado, :salas, &Map.put($1, nombre_sala, []))
          end
          :timer.sleep(200)
          ciclo(estado_nuevo)

      {:unirse_sala, pid, nombre_sala} ->
        if Map.has_key?(estado.salas, nombre_sala) do
          actualizar_salas = Map.update!(estado.salas, nombre_sala, fn usuarios -> [nombre_usuario | usuarios] end)
          send(de, {:ok, "#{nombre_usuario} se unió a la sala #{nombre_sala}."})
          ciclo(%{estado | salas: actualizar_salas})
        else
          send(de, {:error, "Sala no encontrada."})
          ciclo(estado)
        end

      {:enviar_mensaje, nombre_usuario, nombre_sala, mensaje} ->
        IO.puts("[#{nombre_sala}] #{nombre_usuario}: #{mensaje}")
        Util.guardar_mensaje(nombre_sala, "[#{nombre_sala}] #{nombre_usuario}: #{mensaje}")
        ciclo(estado)

      {:listar_usuarios, de} ->
        usuarios = Map.keys(estado.usuarios)
        send(de, {:ok, usuarios})
        ciclo(estado)

      {:historial, nombre_sala, de} ->
        mensajes = Util.cargar_mensajes(nombre_sala)
        send(de, {:ok, mensajes})
        ciclo(estado)
      end
    end
  end
