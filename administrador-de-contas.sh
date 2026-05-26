#!/bin/bash

# Função para pausar a tela até que o usuário aperte Enter
pausa() {
    echo ""
    read -p "Pressione [Enter] para continuar..."
}

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script precisa ser executado como root (sudo)."
    exit 1
fi

while true; do
    clear
    echo "============================================="
    echo "    PAINEL DE GERENCIAMENTO DE USUÁRIOS      "
    echo "============================================="
    echo "1. Criar novo usuário"
    echo "2. Adicionar usuário a um grupo"
    echo "3. Bloquear conta de usuário"
    echo "4. Desbloquear conta de usuário"
    echo "5. Excluir usuário"
    echo "6. Listar todos os usuários (com status)"
    echo "7. Criar novo grupo"
    echo "8. Excluir grupo"
    echo "9. Verificar se usuário já existe"
    echo "10. Gerar relatório de usuários e grupos"
    echo "0. Sair"
    echo "============================================="
    read -p "Escolha uma opção: " opcao

    case $opcao in
        1)
            read -p "Digite o nome do novo usuário: " usuario
            if id "$usuario" &>/dev/null; then
                echo "Erro: O usuário '$usuario' já existe!"
            else
                while true; do 
                    read -s -p "Digite a nova senha (mínimo 8 caracteres): " senha
                    echo ""
                    
                    # Validação estrita de 8 caracteres do script
                    if [ ${#senha} -lt 8 ]; then
                        echo "Erro: A senha é muito curta! Escolha outra."
                        continue
                    fi

                    # O usuário SÓ é criado se a senha passar da validação acima
                    useradd -m "$usuario"
                    echo "$usuario:$senha" | chpasswd 2>/dev/null
                    
                    echo "Usuário Criado com Sucesso!"
                    break
                done
            fi
            pausa
            ;;
        0)
            echo "Saindo do administrador. Até logo!"
            exit 0
            ;;
        *)
            echo "Opção inválida! Tente novamente."
            pausa
            ;;
    esac
done
