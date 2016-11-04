# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Hsbc < Base # Banco HSBC
      validates_inclusion_of :carteira, in: %w( CNR CSB )
      validates_length_of :agencia, maximum: 4
      validates_length_of :numero, maximum: 13
      validates_length_of :conta_corrente, maximum: 7

      # Nova instancia do Hsbc
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = { carteira: 'CNR' }.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '399'
      end

      # Número seqüencial utilizado para identificar o boleto.
      # @return [String] 13 caracteres numéricos.
      def numero=(valor)
        @numero = valor.to_s.rjust(13, '0') if valor
      end

      # Número seqüencial utilizado para identificar o boleto.
      #
      # O desenvolvedor poderá informar o código do nosso número quando gerado pelo banco
      # @param valor Nosso número
      attr_writer :nosso_numero

      # Número seqüencial utilizado para identificar o boleto.
      #
      # Montagem é baseada na presença da data de vencimento.<br/>
      # <b>OBS:</b> Somente as carteiras <b>CNR/CSB</b> estão implementadas.<br/>
      #
      # @return [String]
      # @raise  [Brcobranca::NaoImplementado] Caso a carteira informada não for CNR/CSB.
      def nosso_numero
        case carteira
        when 'CNR' then
          if data_vencimento.is_a?(Date)
            self.codigo_servico = '4'
            dia = data_vencimento.day.to_s.rjust(2, '0')
            mes = data_vencimento.month.to_s.rjust(2, '0')
            ano = data_vencimento.year.to_s[2..3]
            data = "#{dia}#{mes}#{ano}"

            parte_1 = "#{numero}#{numero.modulo11(mapeamento: { 10 => 0 })}#{codigo_servico}"
            soma = parte_1.to_i + conta_corrente.to_i + data.to_i
            "#{parte_1}#{soma.to_s.modulo11(mapeamento: { 10 => 0 })}"
          else
            self.errors[:data_vencimento] = 'não é uma data.'
            fail Brcobranca::BoletoInvalido.new(self)
          end
        when 'CSB'
          @nosso_numero
        else
          fail Brcobranca::NaoImplementado.new('Tipo de carteira não implementado.')
          # TODO - Verificar outras carteiras.
          # self.codigo_servico = "5"
          # parte_1 = "#{self.numero}#{self.numero.modulo11(mapeamento: { 10 => 0 })}#{self.codigo_servico}"
          # soma = parte_1.to_i + self.conta_corrente.to_i
          # numero = "#{parte_1}#{soma.to_s.modulo11(mapeamento: { 10 => 0 })}"
          # numero
        end
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "0000000004042847"
      def nosso_numero_boleto
        nosso_numero
      end

      # Número do convênio/contrato do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0061900"
      def agencia_conta_boleto
        conta_corrente
      end

      # Segunda parte do código de barras.
      #
      # Montagem é baseada no tipo de carteira e na presença da data de vencimento<br/>
      # <b>OBS:</b> Somente as carteiras <b>CNR/CSB</b> estão implementadas.<br/>
      #
      # @return [String] 25 caracteres numéricos.
      # @raise  [Brcobranca::NaoImplementado] Caso a carteira informada não for CNR/CSB.
      def codigo_barras_segunda_parte
        case carteira
        when 'CNR'
          dias_julianos = data_vencimento.to_juliano
          "#{conta_corrente}#{numero}#{dias_julianos}2"
        when 'CSB'
          fail Brcobranca::NaoImplementado.new('Nosso número não definido.') unless @nosso_numero
          "#{nosso_numero}#{agencia}#{conta_corrente}001"
        else
          fail Brcobranca::NaoImplementado.new('Tipo de carteira não implementado.')
        end
      end
    end
  end
end
