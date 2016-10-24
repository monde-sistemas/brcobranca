# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class BancoNordeste < Base # Banco do Nordeste
      validates_length_of :agencia, maximum: 4, message: 'deve ser menor ou igual a 4 dígitos.'
      validates_length_of :convenio, maximum: 7, message: 'deve ser menor ou igual a 7 dígitos.'
      validates_length_of :carteira, maximum: 2, message: 'deve ser menor ou igual a 2 dígitos.'
      validates_length_of :numero, maximum: 7, message: 'deve ser menor ou igual a 7 dígitos.'

      # Nova instancia do Banco do Nordeste
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = { carteira: '21' }.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '004'
      end

      # Número da conta corrente
      # @return [String] 7 caracteres numéricos.
      def conta_corrente=(valor)
        @conta_corrente = valor.to_s.rjust(7, '0') if valor
      end

      # Número do convênio/contrato do cliente junto ao banco.
      # @return [String] 7 caracteres numéricos.
      def convenio=(valor)
        @convenio = valor.to_s.rjust(7, '0') if valor
      end

      # Número sequencial utilizado para identificar o boleto.
      # @return [String] 8 caracteres numéricos.
      def numero=(valor)
        @numero = valor.to_s.rjust(7, '0') if valor
      end

      # Dígito verificador do nosso número.
      # @return [String] 1 caracteres numéricos.
      def nosso_numero_dv
        nosso_numero = numero.to_s.rjust(7, '0') unless numero.nil?
        nosso_numero.modulo11(
          multiplicador: (2..8).to_a,
          mapeamento: { 10 => 0, 11 => 0 }
        ) { |total| 11 - (total % 11) }
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "0020572-9"
      def nosso_numero_boleto
        nosso_numero = numero.to_s.rjust(7, '0') unless numero.nil?
        "#{nosso_numero}-#{nosso_numero_dv}   #{carteira}"
      end

      # Agência + codigo do cedente do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0059/1899775"
      def agencia_conta_boleto
        "#{agencia}/#{convenio_com_dv}"
      end

      # Dígito verificador da convênio
      # @return [Integer] 1 caracteres numéricos.
      def convenio_dv
        convenio.modulo11
      end

      def convenio_com_dv
        "#{convenio}-#{convenio_dv}"
      end

      # Segunda parte do código de barras.
      # 9(04) | Agência <br/>
      # 9(08) | Convenio com DV <br/>
      # 9(08) | Nosso Numero Com DV<br/>
      # 9(02) | Carteira<br/>
      # 9(03) | Zeros<br/>
      #
      # @return [String] 25 caracteres numéricos.
      def codigo_barras_segunda_parte
        "#{agencia}#{convenio}#{convenio_dv}#{numero}#{nosso_numero_dv}#{carteira}000"
      end
    end
  end
end
