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
      sequencial_remessa: '1',
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

  context 'header do arquivo' do
    it 'deve ter 240 posicoes' do
      expect(sicoob_banco_brasil.monta_header_arquivo.size).to eq 240
    end

    it 'header arquivo deve ter as informacoes nas posicoes corretas' do
      header = sicoob_banco_brasil.monta_header_arquivo
      expect(header[0..2]).to eq sicoob_banco_brasil.cod_banco        # cod. do banco
      expect(header[3..6]).to eq '0000'                               # cod. do banco
      expect(header[7]).to eq '1'                                     # reg. header do lote
      expect(header[8]).to eq 'R'                                     # tipo da operacao R - remessa
      expect(header[9..15]).to eq ''.rjust(7, '0')                    # zeros
      expect(header[16..17]).to eq '  '                               # brancos
      expect(header[18..39]).to eq sicoob_banco_brasil.info_conta     # informacoes da conta
      expect(header[40..69]).to eq ''.rjust(30, ' ')                  # brancos
      expect(header[70..99]).to eq 'SOCIEDADE BRASILEIRA DE ZOOLOG'   # razao social do cedente
      expect(header[100..179]).to eq ''.rjust(80, ' ')                # brancos
      expect(header[180..187]).to eq '00000001'                       # sequencial de remessa
      expect(header[188..195]).to eq '10122015'                       # data gravacao
      expect(header[196..206]).to eq ''.rjust(11, '0')                # zeros
      expect(header[207..239]).to eq ''.rjust(33, ' ')                # brancos
    end
  end

  context 'geracao remessa' do
    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(sicoob_banco_brasil.gera_arquivo).to eq(read_remessa('remessa-sicoob-correspondente-bb-cnab240.rem', sicoob_banco_brasil.gera_arquivo)) }
    end
  end
end
