defmodule BenchmarkCliente do
  @moduledoc """
  Módulo especializado para ejecutar pruebas de rendimiento del NodoCliente.
  """

  def run_benchmark(fun, descripcion) do
    {tiempo_microsegundos, _resultado} = :timer.tc(fun)
    IO.puts("#{descripcion}: #{tiempo_microsegundos / 1_000} ms")
  end

  def benchmark_autenticacion do
    run_benchmark(fn ->
      servidor_node = :"servidor@192.168.100.91"
      Node.connect(servidor_node)
      usuario = Usuario.autenticar()
      send({:servidor, servidor_node}, {:autenticacion, self(), usuario})

      # Simulación: espera un tiempo fijo o recibe respuesta con timeout
      receive do
        {:autenticado, _} -> :ok
      after
        1_000 -> IO.puts("Advertencia: no se recibió respuesta del servidor, autenticación simulada.")
      end
    end, "Tiempo de autenticación")
  end

  def benchmark_envio_mensaje(sala, mensaje) do
    run_benchmark(fn ->
      servidor_node = :"servidor@192.168.100.91"
      usuario = %Usuario{nombre: "usuario_test"}
      mensaje_cifrado = Util.cifrar_mensaje(mensaje)
      send({:servidor, servidor_node}, {:mensaje_sala, sala, usuario.nombre, mensaje_cifrado})
      :timer.sleep(100) # Simulamos que esperamos respuesta del servidor
    end, "Tiempo de envío de mensaje")
  end

  def benchmark_listar_usuarios do
    run_benchmark(fn ->
      servidor_node = :"servidor@192.168.100.91"
      send({:servidor, servidor_node}, {:listar_usuarios, self()})
      receive do
        {:usuarios, _lista} -> :ok
      after
        1_000 -> IO.puts("Advertencia: no se recibió lista de usuarios, simulación.")
      end
    end, "Tiempo de listar usuarios")
  end

  def benchmark_historial(sala) do
    run_benchmark(fn ->
      servidor_node = :"servidor@192.168.100.91"
      send({:servidor, servidor_node}, {:historial, self(), sala})
      receive do
        {:historial, _mensajes} -> :ok
      after
        1_000 -> IO.puts("Advertencia: no se recibió historial, simulación.")
      end
    end, "Tiempo de obtener historial")
  end

  def benchmark_busqueda(sala, palabra) do
    run_benchmark(fn ->
      servidor_node = :"servidor@192.168.100.91"
      send({:servidor, servidor_node}, {:buscar_mensaje, self(), sala, palabra})
      receive do
        {:resultados_busqueda, _resultados} -> :ok
      after
        1_000 -> IO.puts("Advertencia: no se recibieron resultados de búsqueda, simulación.")
      end
    end, "Tiempo de búsqueda de mensajes")
  end

  def benchmark_completo do
    IO.puts("Iniciando benchmark completo del NodoCliente...\n")

    benchmark_autenticacion()
    benchmark_envio_mensaje("sala_prueba", "Hola a todos!")
    benchmark_listar_usuarios()
    benchmark_historial("sala_prueba")
    benchmark_busqueda("sala_prueba", "Hola")

    IO.puts("\nBenchmark completo finalizado.")
  end
end

if __ENV__.file == __ENV__.file do
  BenchmarkCliente.benchmark_completo()
end
