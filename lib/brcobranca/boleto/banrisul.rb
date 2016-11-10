# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Banrisul < Base # Banco BANRISUL
      validates_length_of :agencia, maximum: 4
      validates_length_of :numero, maximum: 10
      validates_length_of :convenio, maximum: 13
      validates_length_of :carteira, is: 1

      # Nova instancia do Banrisul
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = { carteira: '1' }.merge!(campos)

        campos.merge!(local_pagamento: 'Pagável em qualquer banco até o vencimento')

        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '041'
      end

      # Número seqüencial utilizado para identificar o boleto.
      # @return [String] 10 caracteres numéricos.
      def numero=(valor)
        @numero = valor.to_s.rjust(10, '0') if valor
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "00000004042-28"
      def nosso_numero_boleto
        "#{numero}-#{nosso_numero_dv}"
      end

      def gerar_dac_dvs(campo)
        primeiro_digito = campo.modulo10
        segundo_digito = "#{campo}#{primeiro_digito}".modulo11

        if segundo_digito == 10
          primeiro_digito += 1
          segundo_digito = "#{campo}#{primeiro_digito}".modulo11
        end

        "#{primeiro_digito}#{segundo_digito}"
      end

      # Dígito verificador da agência
      # @return [Integer] 2 caracteres numéricos.
      def agencia_dv
        gerar_dac_dvs(agencia)
      end

      # Dígito verificador do nosso número
      # @return [Integer] 1 caracteres numéricos.
      def nosso_numero_dv
        gerar_dac_dvs(numero)
      end

      # Dígito verificador do convenio
      # @return [Integer] 2 caracteres numéricos.
      def convenio_dv
        gerar_dac_dvs(convenio)
      end

      # Agência + convênio do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0548.23/00001448-26"
      def agencia_conta_boleto
        "#{agencia}.#{agencia_dv}/#{convenio}-#{convenio_dv}"
      end

      # Segunda parte do código de barras.
      #
      # Posição | Tamanho | Conteúdo<br/>
      # 20 a 23 | 4 |  Agência Cedente (Sem o digito verificador, completar com zeros a esquerda quando  necessário)<br/>
      # 24 a 25 | 2 |  Carteira<br/>
      # 26 a 36 | 11 |  Número do Nosso Número(Sem o digito verificador)<br/>
      # 37 a 43 | 7 |  Conta do Cedente (Sem o digito verificador, completar com zeros a esquerda quando necessário)<br/>
      # 44 a 44 | 1 |  Zero<br/>
      #
      # @return [String] 25 caracteres numéricos.
      def codigo_barras_segunda_parte
        "#{agencia}#{carteira}#{numero}#{convenio}"
      end
    end
  end
end
