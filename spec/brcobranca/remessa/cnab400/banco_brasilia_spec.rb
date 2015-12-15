# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::BancoBrasilia do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
      data_vencimento: Date.today,
      nosso_numero: 123,
      documento_sacado: '12345678901',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
      endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
      bairro_sacado: 'São josé dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cássia maria da silva',
      uf_sacado: 'SP')
  end
  let(:params) do
    {
      carteira: '2',
      agencia: '083',
      conta_corrente: '0000490',
      digito_conta: '1',
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      pagamentos: [pagamento]
    }
  end
  let(:banco_brasilia) { subject.class.new(params) }

  context 'validacoes dos campos' do
    context '@agencia' do
      it 'deve ser invalido se nao possuir uma agencia' do
        object = subject.class.new(params.merge!(agencia: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Agencia não pode estar em branco.')
      end

      it 'deve ser invalido se a agencia tiver mais de 3 digitos' do
        banco_brasilia.agencia = '1234'
        expect(banco_brasilia.invalid?).to be true
        expect(banco_brasilia.errors.full_messages).to include('Agencia deve ter 3 dígitos.')
      end
    end

    context '@digito_conta' do
      it 'deve ser invalido se nao possuir um digito da conta corrente' do
        objeto = subject.class.new(params.merge!(digito_conta: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Digito conta não pode estar em branco.')
      end

      it 'deve ser inválido se o dígito da conta tiver mais de 1 dígito' do
        banco_brasilia.digito_conta = '12'
        expect(banco_brasilia.invalid?).to be true
        expect(banco_brasilia.errors.full_messages).to include('Digito conta deve ter 1 dígito.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser invalido se nao possuir uma conta corrente' do
        object = subject.class.new(params.merge!(conta_corrente: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Conta corrente não pode estar em branco.')
      end

      it 'deve ser invalido se a conta corrente tiver mais de 7 digitos' do
        banco_brasilia.conta_corrente = '12345678'
        expect(banco_brasilia.invalid?).to be true
        expect(banco_brasilia.errors.full_messages).to include('Conta corrente deve ter 7 dígitos.')
      end
    end

    context '@carteira' do
      it 'deve ser inválido se não possuir uma carteira' do
        object = subject.class.new(params.merge!(carteira: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Carteira não pode estar em branco.')
      end

      it 'deve ser inválido se a carteira tiver 1 dígito' do
        banco_brasilia.carteira = '12'
        expect(banco_brasilia.invalid?).to be true
        expect(banco_brasilia.errors.full_messages).to include('Carteira deve ter 1 dígito.')
      end
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 070' do
      expect(banco_brasilia.cod_banco).to eq '070'
    end

    it 'complemento deve retornar 294 caracteres' do
      expect(banco_brasilia.complemento.size).to eq 294
    end

    it 'info_conta deve retornar com 10 posicoes as informacoes da conta' do
      info_conta = banco_brasilia.info_conta
      expect(info_conta.size).to eq 10
      expect(info_conta[0..3]).to eq '123'        # num. da agencia
      expect(info_conta[6..12]).to eq '1234567'    # num. da conta
    end
  end

  context 'monta remessa' do
    # it_behaves_like 'cnab400'

    context 'header' do
      it 'deve ter 39 posicoes' do
        expect(banco_brasilia.monta_header.size).to eq 39
      end

      it 'informacoes devem estar posicionadas corretamente no header' do
        header = banco_brasilia.monta_header
        expect(header[0..2]).to eq 'DCB'                              # literal DCB
        expect(header[3..5]).to eq '001'                              # versão
        expect(header[6..8]).to eq '075'                              # arquivo
        expect(header[9..18]).to eq banco_brasilia.info_conta         # informacoes da conta
        expect(header[19..32]).to eq DateTime.now.strftime('%Y%m%d%H%M%S')  # data/hora de formação
        expect(header[33..38]).to eq '000002'                         # num. de registros
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = banco_brasilia.monta_detalhe pagamento, 1
        expect(detalhe[62..68]).to eq '0000123'                       # nosso numero
        expect(detalhe[69]).to eq '6'                                 # digito verificador
        expect(detalhe[120..125]).to eq Date.today.strftime('%d%m%y') # data de vencimento
        expect(detalhe[126..138]).to eq '0000000019990'               # valor do titulo
        expect(detalhe[142..145]).to eq '0000'                        # agência cobradora
        expect(detalhe[156..159]).to eq '0000'                        # instrução
        expect(detalhe[220..233]).to eq '00012345678901'              # documento do pagador
        expect(detalhe[234..263]).to eq 'PABLO DIEGO JOSE FRANCISCO DE ' # nome do pagador
      end
    end

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(banco_brasilia.gera_arquivo).to eq(read_remessa('remessa-banco-nordeste-cnab400.rem', banco_nordeste.gera_arquivo)) }
    end
  end
end
