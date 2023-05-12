* Instalação do adaptador de protocolo para Zabbix *

Este programa recebe pacotes de monitoramento de dispositivos diversos
na porta UDP 10051 e injeta-os no receptor Zabbix Trapper TCP.

É destinados a dispositivos mais simples que não tem opção de instalar
o zabbix-agent, ou que rodem em redes restritas onde não é possível o
monitoramento via SNMP.

Enquanto os monitores comuns usam TCP, ele usa o UDP por ser mais
simples e por poder ser configurado em via única no firewall.

Se desejar, pode-se permitir apenas o tráfego do equipamento ao
servidor. Ou seja, apenas 1 pacote UDP irá enviar o conteúdo; sem que
seja necessário o caminho contrário.


* Autenticação, Segurança *

O sistema NÃO implementa autenticação.

Existem diversas desvantagens com relação a um sistema não
autenticado. Porém ele foi concebido assim para poder suportar 2
requisitos:

  - simples de implementar em microcontroladores com poucos KB de
    memória

  - transmissão em um único pacote, sem depender de recepção

Como desvantagens, temos:

  - dispositivos “mal-intencionados” na mesma rede conseguem
    facilmente enviar dados com o hostname de outro dispositivo
  
  - é possível capturar os dados durante o trânsito

A parte de captura dos dados é até interessante. Ela permitiu um
auditor externo com acesso aos switches capturar pacotes e validar as
informações que estão sendo transmitidas.

Cuidado para não deixar a porta UDP aberta para a Internet ou para
redes inseguras, pois o sistema pode ser usado como vetor de ataques:
alguém mal intencionado poderá injetar dados falsos no servidor Zabbix
através dele.

Exemplo de uso “inteligente” para o fato do sistema não possuir
autenticação: em uma das aplicações deste sistema, usei a seguinte
topologia de rede que considero uma alternativa suficientemente
segura:

  - todos os dispositivos rodam dentro de uma VLAN específica
  
  - no gateway de saída para a Internet, os pacotes da porta UDP 10051
    são redirecionados a um link com OpenVPN (client), que trafega
    pela Internet até chegar ao servidor Zabbix (OpenVPN server)
  
  - no servidor Zabbix o firewall está configurado para aceitar a
    porta UDP 10051 apenas quando entrando pela interface do OpenVPN


* Passos da instalação *

1 – verifique se no seu servidor algum serviço usa a mesma porta que o
    adaptador usará, para evitar algum conflito:

	netstat -ulnp | grep :10051
	
    o comando não deverá mostrar resultados, indicando que ninguém usa
    esta porta.

2 – crie a pasta /opt/zabbix-receptor-udp e copie os arquivos cron.sh
    e zabbix_trapper_simpleudp para ela. Certifique-se que os 2
    arquivos tem permissão de execução (chmod 755 nomedoarquivo)

3 – como será a primeira vez que vai executar o programa, crie o
    arquivo que ele usa para ativar o modo debug, assim poderá
    diagnosticar o funcionamento dele:

	touch /tmp/zabbix_trapper_simpleudp.debug

4 – execute o programa

	cd /opt/zabbix-receptor-udp/
	nohup ./cron.sh >/dev/null 2>/dev/null </dev/null &

5 – verifique se ele está ativo na porta UDP

	netstat -ulnp | grep :10051

6 – verifique o conteúdo no arquivo log debug:

	cat /var/log/zabbix_trapper_simpleudp.log
	
    no log irá mostrar uma linha similar a esta:
    
	begin RX:UDP 10051 => TX:TCP 127.0.0.1:10051 DBG=1

7 – configure o programa para executar automaticamente no próximo boot

	echo "@reboot cd /opt/zabbix-receptor-udp/ && ./cron.sh" > /etc/cron.d/zabbix-receptor-udp


* Configurações no Zabbix (exemplo) *

1 – criar um novo host, com host name "simpletest"

2 – dentro do hostname, criar um novo item com os seguintes parâmetros:

     Name: Uptime test
     Type: Zabbix trapper
     Key: uptime

3 – aguarde pelo menos 1 minuto, que é o tempo que o Zabbix precisa
    para efetivar a criação de um novo item trapper


* Envio de pacote de testes (exemplo) *

Pode criar/enviar um pacote exemplo da seguinte forma (exemplo em
bash):

    echo -e "$(date +%s),test:$RANDOM\nsimpletest,uptime,12345" | netcat -u IP-DO-SERVIDOR 10051

No servidor você verá em /var/log/zabbix_trapper_simpleudp.log uma
linha mostrando a recepção do UDP (com a tag UDP:RX) e linhas de
processamento (com a tag GOT:)

Após testar que deu certo, pode desabilitar o modo debug:

  - remova o arquivo que configura o debug:
        rm /tmp/zabbix_trapper_simpleudp.debug

  - crie um arquivo que fará com que o script se reinicie:
        touch /tmp/zabbix_trapper_simpleudp.restart

  - aguarde 10 segundos e olhe o arquivo zabbix_trapper_simpleudp.log
    para conferir que o script reiniciou com o debug desabilitado
    (DBG=0 no log)
