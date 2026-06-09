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
        2)
            read -p "Digite o nome do usuário: " usuario
            read -p "Digite o nome do grupo: " grupo
            if id "$usuario" &>/dev/null && grep -q "^$grupo:" /etc/group; then
                usermod -aG "$grupo" "$usuario"
                echo "Usuário '$usuario' adicionado ao grupo '$grupo' com sucesso!"
            else
                echo "Erro: Usuário ou grupo não encontrado."
            fi
            pausa
            ;;
        3)
            read -p "Digite o nome do usuário para bloquear: " usuario
            if id "$usuario" &>/dev/null; then
                # Verifica o status atual do usuário ('L' significa bloqueado)
                status_atual=$(passwd -S "$usuario" 2>/dev/null | awk '{print $2}')
                
                if [ "$status_atual" = "L" ]; then
                    echo "Aviso: O usuário '$usuario' JÁ ESTAVA bloqueado!"
                else
                    passwd -l "$usuario" > /dev/null
                    echo "Usuário '$usuario' bloqueado com sucesso."
                fi
            else
                echo "Usuário não encontrado."
            fi
            pausa
            ;;

        4)
            read -p "Digite o nome do usuário para desbloquear: " usuario
            if id "$usuario" &>/dev/null; then
                # Verifica o status atual do usuário ('L' significa bloqueado)
                status_atual=$(passwd -S "$usuario" 2>/dev/null | awk '{print $2}')
                
                if [ "$status_atual" != "L" ]; then
                    echo "Aviso: O usuário '$usuario' JÁ ESTAVA desbloqueado!"
                else
                    passwd -u "$usuario" > /dev/null
                    echo "Usuário '$usuario' desbloqueado com sucesso."
                fi
            else
                echo "Usuário não encontrado."
            fi
            pausa
            ;;
        5)
            read -p "Digite o nome do usuário para EXCLUIR: " usuario
            if id "$usuario" &>/dev/null; then
                read -p "Deseja mesmo apagar o usuário? (s/n): " resp
                if [ "$resp" = "s" ] || [ "$resp" = "S" ]; then
                    userdel -r "$usuario" 2>/dev/null

                    echo "Usuário '$usuario' excluido."
                else
                    echo "Usuário não excluido."
                fi
            else
                echo "Usuário não encontrado."
            fi
            pausa
            ;;
        6)
            echo "--- Lista de Usuários e Status ---"
            # Lê apenas usuários comuns e reais (UID >= 1000)
            awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | while read -r user; do
                # Captura a segunda coluna do passwd -S (que será 'L' ou 'P')
                status_raw=$(passwd -S "$user" 2>/dev/null | awk '{print $2}')
                
                # Correção: O Ubuntu usa "L" para Locked (Bloqueado)
                if [ "$status_raw" = "L" ]; then
                    status="BLOQUEADO"
                else
                    status="ATIVO"
                fi
                echo "Usuário: $user | Status: $status"
            done
            pausa
            ;;
        7)
            read -p "Digite o nome do novo grupo: " grupo
            
            # Verifica se o grupo já existe
            if grep -q "^$grupo:" /etc/group; then
                echo "Erro: O grupo '$grupo' já existe."
            # Verifica se o nome digitado está vazio
            elif [ -z "$grupo" ]; then
                echo "Erro: O nome do grupo não pode ficar vazio."
            else
                # Tenta criar o grupo. O '2>&1' captura mensagens de erro do groupadd
                # e permite que o if avalie se o comando deu certo ou errado.
                erro_msg=$(groupadd "$grupo" 2>&1)
                
                if [ $? -eq 0 ]; then
                    echo "Grupo '$grupo' criado com sucesso!"
                else
                    echo -e "\nErro ao criar o grupo: $erro_msg"
                    echo -e "Regras importantes:\n"
                    echo -e "  * Não pode conter apenas números"
                    echo -e "  * Não utilize espaços"
                    echo -e "  * Para usar mais de uma palavra, siga estes modelos:"
                    echo -e "    [+] vivaBem"
                    echo -e "    [+] viva_bem"
                    echo -e "    [+] viva-bem"

                fi
            fi
            pausa
            ;;
        8)
            read -p "Digite o nome do grupo que deseja EXCLUIR: " grupo
            if grep -q "^$grupo:" /etc/group; then
                read -p "Tem certeza que deseja excluir o grupo? (s/n): " resp
        
                if [ "$resp" = "s" ] || [ "$resp" = "S" ]; then
                    groupdel "$grupo"
                    echo "Grupo '$grupo' excluído com sucesso!"
                else
                    echo "Operação cancelada."
                fi
            else
                echo "Grupo não encontrado."
            fi
            pausa
            ;;
        9)
            read -p "Digite o nome do usuário que deseja verificar: " usuario
            if id "$usuario" &>/dev/null; then
                echo "O usuário '$usuario'"
            else
                echo "O usuário '$usuario' NÃO existe."
            fi
            pausa
            ;;
        10)
            VERDE="\033[0;32m"
            RESET="\033[0m"
            echo -e "\n------------- Gerando Relatório Detalhado ------------------------"
    
            echo "=================================================================="
            echo "         RELATÓRIO AUDITADO DE USUÁRIOS E GRUPOS"
            echo "         Gerado em: $(date '+%d/%m/%Y às %H:%M:%S')"
            echo "=================================================================="
            echo ""
            echo "---------------- STATUS DOS USUÁRIOS -----------------------------"
            echo ""
            printf "%-15s %-10s %-22s %-20s\n" "USUÁRIO" "STATUS" "ÚLTIMO ACESSO" "HOME"
            echo "------------------------------------------------------------------"
            
            while IFS=: read -r user x uid gid comment home shell; do
                if [ "$uid" -ge 1000 ] && [ "$user" != "nobody" ]; then
                    status_raw=$(passwd -S "$user" 2>/dev/null | awk '{print $2}')
                    if [ "$status_raw" == "L" ]; then status="BLOQUEADO"; else status="ATIVO"; fi

                    linha_last=$(last "$user" | head -n 1)
                    
                    if [ -z "$linha_last" ]; then
                        acesso_formatado="Nunca logou"
                    elif echo "$linha_last" | grep -q "still logged in"; then
                        acesso_formatado="Logado agora"
                    else
                        acesso_formatado=$(echo "$linha_last" | awk '{print $4, $5, $6, $7}')
                        
                        if [ -z "$acesso_formatado" ]; then
                            acesso_formatado="Nunca logou"
                        fi
                    fi
                    
                    printf "%-15s %-10s %-22s %-20s\n" "$user" "$status" "$acesso_formatado" "$home"
                fi
            done < /etc/passwd

            echo ""
            echo "------------ GRUPOS DO SISTEMA E SEUS MEMBROS --------------------"
            echo ""
            printf "%-25s %-10s %-40s\n" "NOME DO GRUPO" "GID" "USUÁRIOS NO GRUPO"
            echo "------------------------------------------------------------------"

            # Variável para contar quantos grupos válidos foram listados
            contador_grupos=0

            while IFS=: read -r gname gpasswd gid gmembers; do
                if [ "$gid" -ge 1000 ] && [ "$gname" != "nogroup" ]; then
                    membros="$gmembers"
                    usuarios_primarios=$(awk -F: -v gid_busca="$gid" '$4 == gid_busca {printf "%s,", $1}' /etc/passwd)
                    todos_membros="${usuarios_primarios}${membros}"
                    todos_membros=$(echo "$todos_membros" | sed 's/,$//' | sed 's/^,//' | sed 's/,,/,/g')
                    
                    if [ "$gname" == "$todos_membros" ]; then
                        continue
                    fi

                    if [ -z "$todos_membros" ]; then
                        todos_membros="(Nenhum usuário)"
                    fi
                    
                    printf "%-25s %-10s %-40s\n" "$gname" "$gid" "$todos_membros"
                    
                    # Incrementa o contador toda vez que um grupo é exibido
                    contador_grupos=$((contador_grupos + 1))
                fi
            done < /etc/group

            # Se nenhum grupo foi contabilizado no loop, exibe a mensagem personalizada
            if [ "$contador_grupos" -eq 0 ]; then
                echo "Nenhum grupo criado"
            fi

            echo ""
            echo -e "${VERDE}Relatório gerado com sucesso!${RESET}"
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
