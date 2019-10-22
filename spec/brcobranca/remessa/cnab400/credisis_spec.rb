# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Credisis, type: :model do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
                                       data_vencimento: Date.new(2019, 9, 13),
                                       data_emissao: Date.new(2019, 9, 10),
                                       nosso_numero: 123,
                                       documento: 6969,
                                       dias_protesto: '6',
                                       valor_mora: '8.00',
                                       percentual_multa: '2.00',
                                       documento_sacado: '12345678901',
                                       nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
                                       logradouro_sacado: 'RUA RIO GRANDE DO SUL',
                                       numero_sacado: '190',
                                       bairro_sacado: 'São josé dos quatro apostolos magros',
                                       cep_sacado: '12345678',
                                       cidade_sacado: 'Santa rita de cássia maria da silva',
                                       uf_sacado: 'SP',
                                       codigo_juros: '2',
                                       codigo_multa: '2')
  end
  let(:params) do
    {
      carteira: '18',
      agencia: '1',
      conta_corrente: '2',
      convenio: '0027',
      nome_cedente: 'ANDERSON WILLIAN MACEDO',
      logradouro_cedente: 'RUA DOS BOBOS',
      numero_cedente: '0',
      complemento_cedente: 'CASA MUITO ENGRAÇADA',
      bairro_cedente: 'BAIRRO DO ESMERO',
      cidade_cedente: 'JABULANDIA',
      uf_cedente: 'BA',
      cep_cedente: '18016335',
      documento_cedente: '12345678901234',
      digito_conta: '7',
      sequencial_remessa: '3',
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      pagamentos: [pagamento]
    }
  end
  let(:credisis) { described_class.new(params) }

  describe 'validações' do
    it { is_expected.to validate_presence_of(:agencia) }
    it { is_expected.to validate_length_of(:agencia).is_at_most(4) }
    it { is_expected.to validate_presence_of(:digito_conta) }
    it { is_expected.to validate_length_of(:digito_conta).is_at_most(1) }
    it { is_expected.to validate_presence_of(:conta_corrente) }
    it { is_expected.to validate_length_of(:conta_corrente).is_at_most(8) }
    it { is_expected.to validate_presence_of(:convenio) }
    it { is_expected.to validate_length_of(:convenio).is_at_most(6) }
    it { is_expected.to validate_presence_of(:carteira) }
    it { is_expected.to validate_length_of(:carteira).is_at_most(2) }
    it { is_expected.to validate_presence_of(:sequencial_remessa) }
    it { is_expected.to validate_length_of(:sequencial_remessa).is_at_most(7) }
    it { is_expected.to validate_presence_of(:nome_cedente) }
    it { is_expected.to validate_presence_of(:logradouro_cedente) }
    it { is_expected.to validate_presence_of(:numero_cedente) }
    it { is_expected.to validate_presence_of(:bairro_cedente) }
    it { is_expected.to validate_presence_of(:cep_cedente) }
    it { is_expected.to validate_presence_of(:cidade_cedente) }
    it { is_expected.not_to validate_presence_of(:complemento_cedente) }
    it { is_expected.not_to validate_presence_of(:instrucoes) }
  end

  describe "pagamentos=" do
    context "quando o campo validar_numero_sacado é falso" do
      before { pagamento.validar_numero_sacado = false }

      it "altera valor para verdadeiro" do
        expect(credisis.pagamentos.first.validar_numero_sacado).to be true
      end
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 097' do
      expect(credisis.cod_banco).to eq '097'
      expect(credisis.nome_banco.strip).to eq 'CENTRALCREDI'
    end

    it 'info_conta deve retornar com 20 posicoes as informacoes da conta' do
      info_conta = credisis.info_conta
      expect(info_conta.size).to eq 20
      expect(info_conta[0..3]).to eq '0001'          # num. da agencia
      expect(info_conta[5..12]).to eq '00000002'     # num. da conta
      expect(info_conta[13]).to eq '7'               # dígito da conta
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informacoes devem estar posicionadas corretamente no header' do
        header = credisis.monta_header
        expect(header[1]).to eq '1'                                   # tipo operacao (1 = remessa)
        expect(header[2..8]).to eq 'REMESSA'                          # literal da operacao
        expect(header[26..45]).to eq credisis.info_conta              # informacoes da conta
        expect(header[76..78]).to eq '097'                            # codigo do banco
        expect(header[100..106]).to eq '0000003'                      # sequencial da remessa
        expect(header[107..390]).to eq ' ' * 284                      # brancos
        expect(header[391..393]).to eq '001'                          # versão do arquivo
        expect(header[394..399]).to eq '000001'                       # nr sequencial do revistro
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = credisis.monta_detalhe pagamento, 1
        expect(detalhe[0]).to eq '1'                                                # registro detalhe
        expect(detalhe[1..2]).to eq '02'                                            # tipo do documento do cedente
        expect(detalhe[3..16]).to eq '12345678901234'                               # documento do cedente
        expect(detalhe[17..20]).to eq '0001'                                        # agência
        expect(detalhe[21..28]).to eq '00000002'                                    # conta corrente
        expect(detalhe[29]).to eq '7'                                               # dígito da conta corrente
        expect(detalhe[30..55]).to eq ' ' * 26                                      # brancos
        expect(detalhe[56..75]).to eq '09710001000027000123'                        # nosso numero
        expect(detalhe[76..77]).to eq '01'                                          # código da operacão
        expect(detalhe[78..83]).to eq Date.current.strftime('%d%m%y')               # data da operacão
        expect(detalhe[84..89]).to eq ' ' * 6                                       # brancos
        expect(detalhe[90..91]).to eq '01'                                          # parcela
        expect(detalhe[92]).to eq '3'                                               # tipo pagamento
        expect(detalhe[93]).to eq '3'                                               # tipo recebimento
        expect(detalhe[94..95]).to eq '02'                                          # especie titulo
        expect(detalhe[96]).to eq '2'                                               # tipo protesto
        expect(detalhe[97..98]).to eq '06'                                          # dias protesto
        expect(detalhe[99..100]).to eq '03'                                         # tipo de envio do protesto
        expect(detalhe[101..109]).to eq ' ' * 9                                     # brancos
        expect(detalhe[110..119]).to eq '6969      '                                # numero documento
        expect(detalhe[120..125]).to eq '130919'                                    # vencimento do documento
        expect(detalhe[126..138]).to eq '0000000019990'                             # valor do documento
        expect(detalhe[139..144]).to eq '130919'                                    # data limite do pagamento
        expect(detalhe[145..149]).to eq ' ' * 5                                     # brancos
        expect(detalhe[150..155]).to eq '100919'                                    # data de emissao
        expect(detalhe[156]).to eq ' '                                              # data de emissao
        expect(detalhe[157..158]).to eq '01'                                        # tipo do documento do sacado
        expect(detalhe[159..172]).to eq '00012345678901'                            # cpf/cnpj sacado
        expect(detalhe[173..212]).to eq 'PABLO DIEGO JOSE FRANCISCO DE PAULA JUAN'  # nome do sacado
        expect(detalhe[213..237]).to eq ' ' * 25                                    # nome fantasia
        expect(detalhe[238..272]).to eq 'RUA RIO GRANDE DO SUL              '       # endereco do sacado
        expect(detalhe[273..278]).to eq '190   '                                    # bairro do sacado
        expect(detalhe[304..328]).to eq 'Santa rita de cassia mari'                 # cidade do sacado
        expect(detalhe[329..330]).to eq 'SP'                                        # uf do sacado
        expect(detalhe[331..338]).to eq '12345678'                                  # cep do sacado
        expect(detalhe[339..349]).to eq ' ' * 11                                    # celular do sacado
        expect(detalhe[350..392]).to eq ' ' * 43                                    # email do sacado
        expect(detalhe[393]).to eq ' '                                              # brancos
        expect(detalhe[394..399]).to eq '000001'                                    # sequencial remessa
      end
    end

    describe '#monta_detalhe_opcional' do
      subject(:detalhe) { credisis.monta_detalhe_opcional(pagamento, 1) }

      let(:credisis) { described_class.new(params.merge!(instrucoes: 'PAGAR ANTES DO VENCIMENTO')) }

      it { expect(detalhe.size).to eq 400 }
      it { expect(detalhe[0]).to eq '2' }
      it { expect(detalhe[1..2]).to eq '02' }
      it { expect(detalhe[3..16]).to eq '12345678901234' }
      it { expect(detalhe[17..56]).to eq 'ANDERSON WILLIAN MACEDO                 ' }
      it { expect(detalhe[57..91]).to eq 'RUA DOS BOBOS                      ' }
      it { expect(detalhe[92..97]).to eq '0     ' }
      it { expect(detalhe[98..122]).to eq 'CASA MUITO ENGRACADA     ' }
      it { expect(detalhe[123..147]).to eq 'BAIRRO DO ESMERO         ' }
      it { expect(detalhe[148..172]).to eq 'JABULANDIA               ' }
      it { expect(detalhe[173..174]).to eq 'BA' }
      it { expect(detalhe[175..182]).to eq '18016335' }
      it { expect(detalhe[183]).to eq ' ' }
      it { expect(detalhe[184..282]).to include 'PAGAR ANTES DO VENCIMENTO' }
      it { expect(detalhe[283]).to eq ' ' }
      it { expect(detalhe[284..298]).to eq '000000000000800' }
      it { expect(detalhe[299]).to eq 'P' }
      it { expect(detalhe[300]).to eq '2' }
      it { expect(detalhe[301..302]).to eq '00' }
      it { expect(detalhe[303..317]).to eq '000000000000200' }
      it { expect(detalhe[318]).to eq 'P' }
      it { expect(detalhe[319]).to eq '2' }
      it { expect(detalhe[320..321]).to eq '00' }
      it { expect(detalhe[322..327]).to eq '000000' }
      it { expect(detalhe[328..340]).to eq '0000000000000' }
      it { expect(detalhe[341]).to eq 'I' }
      it { expect(detalhe[342..347]).to eq '000000' }
      it { expect(detalhe[348..360]).to eq '0000000000000' }
      it { expect(detalhe[361]).to eq 'I' }
      it { expect(detalhe[362..367]).to eq '000000' }
      it { expect(detalhe[368..380]).to eq '0000000000000' }
      it { expect(detalhe[381]).to eq 'I' }
      it { expect(detalhe[382..393]).to eq ' ' * 12 }
      it { expect(detalhe[394..399]).to eq '000001' }
    end

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(credisis.gera_arquivo).to eq(read_remessa('remessa-credisis-cnab400.rem', credisis.gera_arquivo)) }
    end
  end
end
