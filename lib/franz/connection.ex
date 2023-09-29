defmodule Franz.Connection do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - stricter checks for opts?
  # TODO(Gordon) - ssl without sasl?
  # TODO(Gordon) - More rigorous testing when answers are found

  use GenServer

  import Franz.Utilities

  @enforce_keys [:config, :endpoints]
  defstruct [:config, :endpoints]

  @type config :: keyword()
  @type endpoints :: [{host :: binary(), port :: non_neg_integer()}]
  @type t :: %__MODULE__{config: config(), endpoints: endpoints()}

  @opts_schema KeywordValidator.schema!(
                 uri: [is: :binary, required: false],
                 host: [is: :binary, required: false],
                 port: [is: :integer, required: false],
                 user: [is: :binary, required: false],
                 pass: [is: :binary, required: false],
                 ssl: [is: :boolean, default: false, required: true],
                 sasl: [
                   is: {:in, [:none, :plain, :scram_sha_256, :scram_sha_512]},
                   default: :none,
                   required: true
                 ]
               )

  ################################
  # Public API
  ################################

  @doc """
  Starts the connection process.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns a connection struct representing the given process.
  """
  @spec get(GenServer.name() | pid()) :: t()
  def get(name_or_pid), do: GenServer.call(name_or_pid, :get)

  ################################
  # GenServer Callbacks
  ################################

  @doc false
  @impl GenServer
  @spec init(keyword()) :: {:ok, map()} | {:stop, any()}
  def init(opts) do
    with {:ok, opts} <- validate_keyword(opts, @opts_schema),
         {:ok, state} <- init_state(opts) do
      test_connection(state)
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @doc false
  @impl GenServer
  @spec handle_call(:get, GenServer.from(), map()) :: {:reply, t(), map()}
  def handle_call(:get, _from, state), do: {:reply, struct(__MODULE__, state), state}

  ################################
  # Private API
  ################################

  defp init_state(opts) do
    case Keyword.get(opts, :uri) do
      nil -> build_state(opts)
      uri -> build_state_from_uri(uri, opts)
    end
  end

  defp build_state_from_uri(uri, opts) do
    with {:ok, opts} <- update_opts(uri, opts) do
      build_state(opts)
    end
  end

  defp update_opts(uri, opts) do
    uri = URI.parse(uri)
    opts = Keyword.merge(opts, host: uri.host, port: uri.port)

    case uri.userinfo do
      nil ->
        {:ok, opts}

      userinfo ->
        [user, pass] = String.split(userinfo, ":")
        opts = Keyword.merge(opts, user: user, pass: pass)
        {:ok, opts}
    end
  rescue
    MatchError -> {:error, :invalid_uri}
  end

  defp build_state(opts) do
    host = Keyword.get(opts, :host)
    port = Keyword.get(opts, :port)
    endpoints = [{host, port}]

    config =
      case Keyword.get(opts, :sasl) do
        :none ->
          []

        sasl ->
          user = Keyword.get(opts, :user)
          pass = Keyword.get(opts, :pass)
          ssl = Keyword.get(opts, :ssl)
          [sasl: {sasl, user, pass}, ssl: ssl]
      end

    {:ok, %{config: config, endpoints: endpoints}}
  end

  defp test_connection(state) do
    case :brod.get_metadata(state.endpoints, :all, state.config) do
      {:ok, _} -> {:ok, state}
      {:error, reason} -> {:stop, reason}
    end
  end
end
