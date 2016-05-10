# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::Sicoob do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 50.0,
      data_vencimento: Date.today,
      nosso_numero: '429715',
      documento_sacado: '82136760505',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
      endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
      bairro_sacado: 'São josé dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cássia maria da silva',
      uf_sacado: 'RJ',
      tipo_mora: '0',
      codigo_protesto: '1'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '4327',
      conta_corrente: '03666',
      documento_cedente: '74576177000177',
      modalidade_carteira: '01',
      pagamentos: [pagamento]
    }
  end

  let(:sicoob) { subject.class.new(params) }

  context 'validacoes' do
    context '@modalidade_carteira' do
      it 'deve ser invalido se nao possuir a modalidade da carteira' do
        objeto = subject.class.new(params.merge(modalidade_carteira: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Modalidade carteira não pode estar em branco.')
      end
    end

    context '@tipo_formulario' do
      it 'deve ser invalido se nao possuir o tipo de formulario' do
        objeto = subject.class.new(params.merge(tipo_formulario: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Tipo formulario não pode estar em branco.')
      end
    end

    context '@parcela' do
      it 'deve ser invalido se nao possuir a parcela' do
        objeto = subject.class.new(params.merge(parcela: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Parcela não pode estar em branco.')
      end
    end

    context '@agencia' do
      it 'deve ser invalido se a agencia tiver mais de 4 digitos' do
        sicoob.agencia = '12345'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser invalido se a conta corrente tiver mais de 8 digitos' do
        sicoob.conta_corrente = '123456789'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Conta corrente deve ter 8 dígitos.')
      end
    end
  end

  context 'formatacoes' do
    it 'codigo do banco deve ser 001' do
      expect(sicoob.cod_banco).to eq '756'
    end

    it 'nome do banco deve ser Sicoob com 30 posicoes' do
      nome_banco = sicoob.nome_banco
      expect(nome_banco.size).to eq 30
      expect(nome_banco[0..19]).to eq 'SICOOB              '
    end

    it 'versao do layout do arquivo deve ser 081' do
      expect(sicoob.versao_layout_arquivo).to eq '081'
    end

    it 'versao do layout do lote deve ser 040' do
      expect(sicoob.versao_layout_lote).to eq '040'
    end

    it 'deve calcular o digito da agencia' do
      # digito calculado a partir do modulo 11 com base 9
      #
      # agencia = 1  2  3  4
      #
      #           4  3  2  1
      # x         9  8  7  6
      # =         36 24 14 6 = 80
      # 80 / 11 = 7 com resto 3
      expect(sicoob.digito_agencia).to eq '3'
    end

    it 'deve calcular  digito da conta' do
      # digito calculado a partir do modulo 11 com base 9
      #
      # conta = 1  2  3  4  5
      #
      #         5  4  3  2  1
      # x       9  8  7  6  5
      # =       45 32 21 12 5 = 116
      # 116 / 11 = 10 com resto 5
      expect(sicoob.digito_conta).to eq '8'
    end

    it 'cod. convenio deve retornar as informacoes nas posicoes corretas' do
      cod_convenio = sicoob.codigo_convenio
      expect(cod_convenio[0..19]).to eq '                    '
    end

    it 'info conta deve retornar as informacoes nas posicoes corretas' do
      info_conta = sicoob.info_conta
      expect(info_conta[0..4]).to eq '04327'
      expect(info_conta[5]).to eq '3'
      expect(info_conta[6..17]).to eq '000000003666'
      expect(info_conta[18]).to eq '8'
    end

    it 'complemento header deve retornar espacos em branco' do
      expect(sicoob.complemento_header).to eq ''.rjust(29, ' ')
    end

    it 'monta segmento R' do
      segmento_r = sicoob.monta_segmento_r(pagamento, 1, 4)
      expect(segmento_r[0..2]).to eq "756"                    # codigo banco
      expect(segmento_r[3..6]).to eq "0001"                   # lote de servico
      expect(segmento_r[7]).to eq "3"                         # tipo de registro
      expect(segmento_r[8..12]).to eq "00004"                 # nro seq. registro no lote
      expect(segmento_r[13]).to eq "R"                        # cod. segmento
      expect(segmento_r[14]).to eq " "                        # branco
      expect(segmento_r[15..16]).to eq "01"                   # cod. movimento remessa
      expect(segmento_r[17..40]).to eq "".rjust(24,  '0')     # desconto 2
      expect(segmento_r[41..64]).to eq "".rjust(24,  '0')     # desconto 3
      expect(segmento_r[65]).to eq '0'                        # cod. multa
      expect(segmento_r[66..73]).to eq ''.rjust(8, '0')       # data multa
      expect(segmento_r[74..88]).to eq ''.rjust(15, '0')      # valor multa
      expect(segmento_r[89..98]).to eq ''.rjust(10, ' ')      # info pagador
      expect(segmento_r[99..138]).to eq ''.rjust(40, ' ')     # mensagem 3
      expect(segmento_r[139..178]).to eq ''.rjust(40, ' ')    # mensagem 4
      expect(segmento_r[179..198]).to eq ''.rjust(20, ' ')    # Exclusivo FEBRABAN
      expect(segmento_r[199..206]).to eq ''.rjust(8, '0')     # Cod. Ocor Pagador
      expect(segmento_r[207..209]).to eq ''.rjust(3, '0')     # Cod. do Banco conta débito
      expect(segmento_r[210..214]).to eq ''.rjust(5, '0')     # Cod. da Agencia de  débito
      expect(segmento_r[215]).to eq ' '                       # Cod. verificador da agencia
      expect(segmento_r[216..227]).to eq ''.rjust(12, '0')    # Conta corrente para débito
      expect(segmento_r[228]).to eq ' '                       # Cod. verificador da conta
      expect(segmento_r[229]).to eq ' '                       # Cod. verificador da ag/conta
      expect(segmento_r[230]).to eq '0'                       # Aviso débito automático
      expect(segmento_r[231..239]).to eq ''.rjust(9, ' ')     # Exclusivo FEBRABAN

    end

    it 'complemento trailer deve retornar espacos em branco com a totalização das cobranças' do
      total_cobranca_simples    = "00000100000000000005000"
      total_cobranca_vinculada  = "".rjust(23, "0")
      total_cobranca_caucionada = "".rjust(23, "0")
      total_cobranca_descontada = "".rjust(23, "0")

      expect(sicoob.complemento_trailer).to eq "#{total_cobranca_simples}#{total_cobranca_vinculada}"\
                            "#{total_cobranca_caucionada}#{total_cobranca_descontada}".ljust(217, ' ')
    end

    it 'formata o nosso numero' do
      nosso_numero = sicoob.formata_nosso_numero 1
      expect(nosso_numero).to eq "000000000101014     "
    end
  end

  context 'geracao remessa' do
    it_behaves_like 'cnab240'

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(sicoob.gera_arquivo).to eq(read_remessa('remessa-bancoob-cnab240.rem', sicoob.gera_arquivo)) }
    end
  end
end
