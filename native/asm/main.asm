# Sistema de Gerenciamento de Estacionamento
# Versão melhorada - Compatível com MARS

.data
    # Mensagens do menu
    menu_principal: .asciiz "\n===== SISTEMA DE GERENCIAMENTO DE ESTACIONAMENTO =====\n"
    op1:           .asciiz "1. Entrada de Veículo\n"
    op2:           .asciiz "2. Pagamento de Ticket\n"
    op3:           .asciiz "3. Saída de Veículo\n"
    op4:           .asciiz "4. Relatórios\n"
    op5:           .asciiz "5. Configurações\n"
    op0:           .asciiz "0. Sair\n"
    escolha:       .asciiz "Escolha uma opção: "
    
    # Mensagens de entrada
    msg_placa:      .asciiz "\nDigite a placa do veículo: "
    msg_vaga:       .asciiz "Digite o número da vaga (0-9): "
    msg_hora_entrada: .asciiz "Hora de entrada (HHMM): "
    msg_entrada_sucesso: .asciiz "\nEntrada registrada com sucesso! Ticket: "
    msg_vaga_ocupada: .asciiz "\nVaga já ocupada! Escolha outra.\n"
    
    # Mensagens de pagamento
    msg_ticket_pagar: .asciiz "\nDigite o número do ticket para pagamento: "
    msg_valor_pagar: .asciiz "Valor a pagar: R$"
    msg_pagamento_sucesso: .asciiz "\nPagamento realizado com sucesso!\n"
    
    # Mensagens de saída
    msg_ticket_saida: .asciiz "\nDigite o número do ticket para saída: "
    msg_saida_sucesso: .asciiz "\nSaída registrada com sucesso!\n"
    
    # Mensagens de relatório
    msg_status_estacionamento: .asciiz "\n=== STATUS DO ESTACIONAMENTO ===\n"
    msg_vaga_status: .asciiz "Vaga "
    msg_ocupada:    .asciiz ": Ocupada - Ticket "
    msg_livre:      .asciiz ": Livre\n"
    msg_tickets_ativos: .asciiz "\nTickets ativos: "
    msg_faturamento: .asciiz "\nFaturamento diário: R$"
    
    # Mensagens gerais
    msg_opcao_invalida: .asciiz "\nOpção inválida! Tente novamente.\n"
    msg_saindo:     .asciiz "\nSaindo do sistema...\n"
    msg_voltar:     .asciiz "\nVoltando ao menu anterior...\n"
    msg_em_desenvolvimento: .asciiz "\nFuncionalidade em desenvolvimento.\n"
    
    # Dados do sistema
    valor_hora:     .float 5.0      # Valor padrão da hora
    faturamento_diario: .float 0.0
    num_vagas:      .word 10
    num_tickets:    .word 0
    
    # Estruturas de dados
    vagas:          .space 40       # 10 vagas (4 bytes cada: 0 = livre, ticket_number = ocupada)
    tickets:        .space 400      # 10 tickets (40 bytes cada: placa(8), vaga(4), entrada(4), saida(4), pago(4), valor(4), reservado(12))
    
    # Buffers para entrada de dados
    buffer_placa:   .space 8
    buffer_vaga:    .space 4
    buffer_hora:    .space 4
    buffer_ticket:  .space 4

.text
.globl main

main:
    # Inicialização do sistema
    jal inicializar_vagas
    
menu_principal_loop:
    # Exibir status do estacionamento
    jal exibir_status
    
    # Exibir menu principal
    li $v0, 4
    la $a0, menu_principal
    syscall
    la $a0, op1
    syscall
    la $a0, op2
    syscall
    la $a0, op3
    syscall
    la $a0, op4
    syscall
    la $a0, op5
    syscall
    la $a0, op0
    syscall
    la $a0, escolha
    syscall
    
    # Ler opção do usuário
    li $v0, 5
    syscall
    move $t0, $v0
    
    # Processar opção
    beq $t0, 1, entrada_veiculo
    beq $t0, 2, pagamento_ticket
    beq $t0, 3, saida_veiculo
    beq $t0, 4, relatorios
    beq $t0, 5, configuracoes
    beq $t0, 0, sair
    
    # Opção inválida
    li $v0, 4
    la $a0, msg_opcao_invalida
    syscall
    j menu_principal_loop

entrada_veiculo:
    # Registrar entrada de veículo
    li $v0, 4
    la $a0, msg_placa
    syscall
    
    # Ler placa (simplificado - apenas 4 caracteres)
    li $v0, 8
    la $a0, buffer_placa
    li $a1, 5
    syscall
    
    # Ler número da vaga
    li $v0, 4
    la $a0, msg_vaga
    syscall
    
    li $v0, 5
    syscall
    move $t1, $v0           # $t1 = número da vaga
    
    # Verificar se vaga é válida (0-9)
    blt $t1, 0, vaga_invalida
    lw $t9, num_vagas
    bge $t1, $t9, vaga_invalida
    
    # Verificar se vaga está disponível
    la $t2, vagas
    sll $t3, $t1, 2         # índice * 4
    add $t2, $t2, $t3
    lw $t4, 0($t2)          # status da vaga
    
    bnez $t4, vaga_ocupada
    
    # Ler hora de entrada
    li $v0, 4
    la $a0, msg_hora_entrada
    syscall
    
    li $v0, 5
    syscall
    move $t5, $v0           # $t5 = hora de entrada
    
    # Registrar ticket
    la $t6, tickets
    lw $t7, num_tickets     # índice do ticket
    move $s0, $t7           # Salvar número do ticket para exibição
    mul $t8, $t7, 40        # 40 bytes por ticket
    add $t6, $t6, $t8
    
    # Salvar placa (simplificado)
    la $t9, buffer_placa
    lw $t0, 0($t9)
    sw $t0, 0($t6)
    
    # Salvar vaga
    sw $t1, 8($t6)
    
    # Salvar hora de entrada
    sw $t5, 12($t6)
    
    # Inicializar outros campos
    sw $zero, 16($t6)       # hora de saída
    sw $zero, 20($t6)       # pago
    sw $zero, 24($t6)       # valor
    
    # Marcar vaga como ocupada (com número do ticket)
    addi $t4, $t7, 1        # Ticket número = índice + 1
    sw $t4, 0($t2)
    
    # Incrementar número de tickets
    addi $t7, $t7, 1
    sw $t7, num_tickets
    
    # Mensagem de sucesso com número do ticket
    li $v0, 4
    la $a0, msg_entrada_sucesso
    syscall
    
    li $v0, 1
    move $a0, $s0
    addi $a0, $a0, 1        # Mostrar ticket número = índice + 1
    syscall
    
    li $v0, 11
    li $a0, '\n'
    syscall
    
    j menu_principal_loop

vaga_invalida:
vaga_ocupada:
    li $v0, 4
    la $a0, msg_vaga_ocupada
    syscall
    j entrada_veiculo

pagamento_ticket:
    # Pagamento de ticket
    li $v0, 4
    la $a0, msg_ticket_pagar
    syscall
    
    # Ler número do ticket
    li $v0, 5
    syscall
    move $t0, $v0           # $t0 = número do ticket
    
    # Verificar se ticket existe (1 a num_tickets)
    blez $t0, ticket_invalido
    lw $t1, num_tickets
    bgt $t0, $t1, ticket_invalido
    
    # Calcular endereço do ticket (índice = ticket - 1)
    la $t2, tickets
    addi $t3, $t0, -1
    mul $t3, $t3, 40
    add $t2, $t2, $t3
    
    # Verificar se já foi pago
    lw $t4, 20($t2)         # status de pagamento
    bnez $t4, ticket_ja_pago
    
    # Simular hora atual (hora de entrada + 100)
    lw $t5, 12($t2)         # hora de entrada
    addi $t6, $t5, 100      # hora atual simulada
    
    # Calcular diferença de horas (simplificado)
    sub $t7, $t6, $t5
    div $t7, $t7, 100       # converter para horas
    
    # Carregar valor da hora
    l.s $f0, valor_hora
    mtc1 $t7, $f1
    cvt.s.w $f1, $f1
    mul.s $f2, $f0, $f1     # valor total
    
    # Mostrar valor a pagar
    li $v0, 4
    la $a0, msg_valor_pagar
    syscall
    
    li $v0, 2
    mov.s $f12, $f2
    syscall
    
    # Nova linha
    li $v0, 11
    li $a0, '\n'
    syscall
    
    # Simular confirmação de pagamento
    li $v0, 4
    la $a0, msg_pagamento_sucesso
    syscall
    
    # Atualizar ticket
    sw $t6, 16($t2)         # hora de saída
    li $t8, 1
    sw $t8, 20($t2)         # marcar como pago
    s.s $f2, 24($t2)        # salvar valor
    
    # Atualizar faturamento
    l.s $f3, faturamento_diario
    add.s $f3, $f3, $f2
    s.s $f3, faturamento_diario
    
    j menu_principal_loop

ticket_invalido:
ticket_ja_pago:
    li $v0, 4
    la $a0, msg_opcao_invalida
    syscall
    j pagamento_ticket

saida_veiculo:
    # Saída de veículo
    li $v0, 4
    la $a0, msg_ticket_saida
    syscall
    
    # Ler número do ticket
    li $v0, 5
    syscall
    move $t0, $v0           # $t0 = número do ticket
    
    # Verificar se ticket existe (1 a num_tickets)
    blez $t0, saida_ticket_invalido
    lw $t1, num_tickets
    bgt $t0, $t1, saida_ticket_invalido
    
    # Calcular endereço do ticket (índice = ticket - 1)
    la $t2, tickets
    addi $t3, $t0, -1
    mul $t3, $t3, 40
    add $t2, $t2, $t3
    
    # Verificar se foi pago
    lw $t4, 20($t2)         # status de pagamento
    beqz $t4, saida_nao_pago
    
    # Liberar vaga
    lw $t5, 8($t2)          # número da vaga
    la $t6, vagas
    sll $t7, $t5, 2
    add $t6, $t6, $t7
    sw $zero, 0($t6)        # liberar vaga
    
    # Mensagem de sucesso
    li $v0, 4
    la $a0, msg_saida_sucesso
    syscall
    
    j menu_principal_loop

saida_ticket_invalido:
saida_nao_pago:
    li $v0, 4
    la $a0, msg_opcao_invalida
    syscall
    j saida_veiculo

relatorios:
    # Menu de relatórios
    li $v0, 4
    la $a0, msg_status_estacionamento
    syscall
    
    # Exibir status das vagas
    la $t0, vagas
    lw $t1, num_vagas
    li $t2, 0               # contador
    
relatorios_loop:
    bge $t2, $t1, relatorios_fim
    
    # Mostrar número da vaga
    li $v0, 4
    la $a0, msg_vaga_status
    syscall
    
    li $v0, 1
    move $a0, $t2
    syscall
    
    # Verificar status
    lw $t3, 0($t0)
    beqz $t3, relatorios_vaga_livre
    
    # Vaga ocupada - mostrar ticket
    li $v0, 4
    la $a0, msg_ocupada
    syscall
    
    li $v0, 1
    move $a0, $t3
    syscall
    
    li $v0, 11
    li $a0, '\n'
    syscall
    j relatorios_prox
    
relatorios_vaga_livre:
    li $v0, 4
    la $a0, msg_livre
    syscall
    
relatorios_prox:
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    j relatorios_loop

relatorios_fim:
    # Mostrar número de tickets ativos
    li $v0, 4
    la $a0, msg_tickets_ativos
    syscall
    
    li $v0, 1
    lw $a0, num_tickets
    syscall
    
    # Mostrar faturamento
    li $v0, 4
    la $a0, msg_faturamento
    syscall
    
    li $v0, 2
    l.s $f12, faturamento_diario
    syscall
    
    # Nova linha
    li $v0, 11
    li $a0, '\n'
    syscall
    
    j menu_principal_loop

configuracoes:
    # Menu de configurações
    li $v0, 4
    la $a0, msg_em_desenvolvimento
    syscall
    j menu_principal_loop

voltar_menu:
    li $v0, 4
    la $a0, msg_voltar
    syscall
    j menu_principal_loop

sair:
    li $v0, 4
    la $a0, msg_saindo
    syscall
    li $v0, 10
    syscall

inicializar_vagas:
    # Inicializar todas as vagas como livres
    la $t0, vagas
    lw $t1, num_vagas
    li $t2, 0
    
inicializar_vagas_loop:
    bge $t2, $t1, inicializar_vagas_fim
    sw $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    j inicializar_vagas_loop
    
inicializar_vagas_fim:
    jr $ra

exibir_status:
    # Exibir status do estacionamento
    li $v0, 4
    la $a0, msg_status_estacionamento
    syscall
    
    # Exibir status das vagas
    la $t0, vagas
    lw $t1, num_vagas
    li $t2, 0               # contador
    
exibir_status_loop:
    bge $t2, $t1, exibir_status_fim
    
    # Mostrar número da vaga
    li $v0, 4
    la $a0, msg_vaga_status
    syscall
    
    li $v0, 1
    move $a0, $t2
    syscall
    
    # Verificar status
    lw $t3, 0($t0)
    beqz $t3, exibir_status_vaga_livre
    
    # Vaga ocupada - mostrar ticket
    li $v0, 4
    la $a0, msg_ocupada
    syscall
    
    li $v0, 1
    move $a0, $t3
    syscall
    
    li $v0, 11
    li $a0, '\n'
    syscall
    j exibir_status_prox
    
exibir_status_vaga_livre:
    li $v0, 4
    la $a0, msg_livre
    syscall
    
exibir_status_prox:
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    j exibir_status_loop

exibir_status_fim:
    # Nova linha
    li $v0, 11
    li $a0, '\n'
    syscall
    
    jr $ra