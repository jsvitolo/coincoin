defmodule Blockchain.P2P.Payload do
  @moduledoc "Data going throught to the P2P protocol"

  alias Blockchain.{Block, P2P.Payload}

  # simple ping
  @ping "ping"

  # to request latest block
  @query_latest "query_latest"

  # to request all the blockchain
  @query_all "query_all"

  # to transmit a block or a blockchain
  @response_blockchain "response_blockchain"

  # to transmit data to be mined
  @mining_request "mining_request"

  @derive [Poison.Encoder]
  defstruct [
    :type,
    :blocks,
    :data
  ]

  def ping, do: %Payload{type: @ping}

  def query_all, do: %Payload{type: @query_all}

  def query_latest, do: %Payload{type: @query_latest}

  def response_blockchain(chain), do: %Payload{type: @response_blockchain, blocks: chain}

  def mining_request(data), do: %Payload{type: @mining_request, data: data}

  defmodule TypedData do
    @moduledoc """
    helper struct to encapsulate the type of the data
    so we can decode back to the original type
    """
    defstruct [:type, :data]
  end

  def encode!(%Payload{} = payload), do: Poison.encode!(payload)

  def decode(input) do
    case Poison.decode(input, as: %Payload{blocks: [%Block{data: %TypedData{}}], data: %TypedData{}}) do
      {:ok, _} = result ->
        result
      {:error, {reason, _, _}} ->
        {:error, reason}
    end
  end

  defimpl Poison.Encoder, for: [Block, Payload] do
    def encode(%{data: data} = struct, options) do
      # embed data into TypedData
      typed_data = typed_data(data)
      %{struct | data: typed_data}
      |> Map.from_struct()
      |> Poison.Encoder.Map.encode(options)
    end

    defp typed_data(%module{} = struct), do: %TypedData{type: module, data: struct}
    defp typed_data(data), do: %TypedData{type: nil, data: data}
  end

  defimpl Poison.Decoder, for: TypedData do
    def decode(%TypedData{type: nil, data: data}, _options), do: data
    def decode(%TypedData{type: type, data: data}, _options) do
      m = for {key, val} <- data, into: %{}, do: {String.to_atom(key), val}
      struct(Module.concat([type]), m)
    end
  end
end
