# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::SicoobBancoBrasil do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 50.0,
      data_vencimento: Date.today,
      nosso_numero: '1234567',
      documento_sacado: '82136760505',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
      endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
      bairro_sacado: 'São josé dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cássia maria da silva',
      uf_sacado: 'RJ'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '4327',
      convenio: '1234567890',
      conta_corrente: '1234567890',
      codigo_cobranca: '1234567',
      documento_cedente: '74576177000177',
      pagamentos: [pagamento]
    }
  end

  let(:sicoob_banco_brasil) { subject.class.new(params) }

  context 'validacoes' do
    context '@agencia' do
      it 'deve ser invalido se a agencia tiver mais de 4 digitos' do
        sicoob_banco_brasil.agencia = '12345'
        expect(sicoob_banco_brasil.invalid?).to be true
        expect(sicoob_banco_brasil.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end

    context '@codigo_cobranca' do
      it 'deve ser invalido se o codigo cobranca tiver mais de 7 digitos' do
        sicoob_banco_brasil.codigo_cobranca = '12345678'
        expect(sicoob_banco_brasil.invalid?).to be true
        expect(sicoob_banco_brasil.errors.full_messages).to include('Codigo cobranca deve ter 7 dígitos.')
      end
    end

    context '@convenio' do
      it 'deve ser invalido se a convenio tiver mais de 10 digitos' do
        sicoob_banco_brasil.convenio = '12345678901'
        expect(sicoob_banco_brasil.invalid?).to be true
        expect(sicoob_banco_brasil.errors.full_messages).to include('Convenio deve ter 10 dígitos.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser invalido se a conta corrente tiver mais de 10 digitos' do
        sicoob_banco_brasil.conta_corrente = '12345678901'
        expect(sicoob_banco_brasil.invalid?).to be true
        expect(sicoob_banco_brasil.errors.full_messages).to include('Conta corrente deve ter 10 dígitos.')
      end
    end
  end

  context 'formatacoes' do
    it 'codigo do banco deve ser 756' do
      expect(sicoob_banco_brasil.cod_banco).to eq '756'
    end

    it 'cod. cobranca deve retornar as informacoes nas posicoes corretas' do
      expect(sicoob_banco_brasil.codigo_cobranca).to eq '1234567'
    end

    it 'info conta deve retornar as informacoes nas posicoes corretas' do
      info_conta = sicoob_banco_brasil.info_conta
      expect(info_conta[0..3]).to eq '4327'           # Agencia
      expect(info_conta[4..10]).to eq '1234567'       # Codigo cobranca
      expect(info_conta[11..21]).to eq '12345678900'  # Conta
    end

    it 'complemento header deve retornar zeros e espacos em branco' do
      info_header = sicoob_banco_brasil.complemento_header
      expect(info_header[0..10]).to eq ''.rjust(11, '0')
      expect(info_header[11..43]).to eq ''.rjust(33, ' ')
    end

    it 'formata o nosso numero' do
      nosso_numero = sicoob_banco_brasil.formata_nosso_numero 1
      expect(nosso_numero).to eq "12345678900000001"
    end
  end

  context 'geracao remessa' do
    # it_behaves_like 'cnab240'

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(sicoob_banco_brasil.gera_arquivo).to eq(read_remessa('remessa-sicoob-correspondente-bb-cnab240.rem', sicoob_banco_brasil.gera_arquivo)) }
    end
  end
end
