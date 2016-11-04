# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Boleto
    class BancoBrasilia < Base # Banco Brasilia
      # Validações
      # Modalidade/Carteira de Cobrança (1-Sem Registro | 2-Registrada)
      validates_length_of :carteira, is: 1
      validates_length_of :convenio, is: 7
      validates_length_of :numero, is: 6

      # Nova instância da BancoBrasilia
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = {
          carteira: '2',
          local_pagamento: 'PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO'
        }.merge!(campos)

        super(campos)
      end

      # Código do banco emissor
      # @return [String]
      def banco
        '070'
      end

      # Número da agência
      # @return [String] 3 caracteres numéricos.
      def agencia=(valor)
        valor = valor.to_s[-3, 3] if valor.size > 3
        @agencia = valor.to_s.rjust(3, '0') if valor
      end

      # Número do convênio/contrato do cliente junto ao banco.
      # @return [String] 7 caracteres numéricos.
      def convenio=(valor)
        @convenio = valor.to_s.rjust(7, '0') if valor
      end

      # Número seqüencial utilizado para identificar o boleto.
      # @return [String] 6 caracteres numéricos.
      def numero=(valor)
        @numero = valor.to_s.rjust(6, '0') if valor
      end

      # Nosso número, 7 dígitos
      # @return [String]
      def nosso_numero_boleto
        "#{nosso_numero}-#{nosso_numero_dv}"
      end

      # Nosso número, 12 dígitos
      #  1 à 2: carteira
      #  3 à 12: campo_livre
      def nosso_numero
        "#{carteira}00000#{numero}"
      end

      # Dígito verificador do Nosso Número
      # Utiliza-se o [-1..-1] para retornar o último caracter
      # @return [String]
      def nosso_numero_dv
        nosso_numero.modulo11(
          multiplicador: (2..9).to_a,
          mapeamento: { 10 => 0, 11 => 0 }
        ) { |total| 11 - (total % 11) }.to_s
      end

      # Número da agência/código cedente do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "1565/100000-4"
      def agencia_conta_boleto
        "#{agencia}/#{convenio}-#{convenio_dv}"
      end

      # Dígito verificador do convênio ou código do cedente
      # @return [String]
      def convenio_dv
        convenio.modulo11(
          multiplicador: (2..9).to_a,
          mapeamento: { 10 => 0, 11 => 0 }
        ) { |total| 11 - (total % 11) }.to_s
      end

      # Monta a segunda parte do código de barras.
      #
      # @return [String]
      def codigo_barras_segunda_parte
        chave = "000#{agencia}#{conta_corrente}#{carteira}#{numero}#{banco}"

        chave << chave.modulo10.to_s
        chave << chave.modulo11(
          multiplicador: (2..7).to_a,
          mapeamento: { 10 => 0, 11 => 0}
        ) { |total| 11 - (total % 11) }.to_s
      end
    end
  end
end
