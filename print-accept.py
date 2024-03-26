from netfilterqueue import NetfilterQueue
from scapy.all import *

def print_and_accept(pkt):
    load_layer("tls")
    #print(pkt)
    sca = IP(pkt.get_payload())
    #print (sca['IP'].src)
    #try:


    if sca.haslayer('TLS') and sca['TLS'].type == 22 and sca['TLS'].msg[0].msgtype == 1:
        
        msg = sca['IP'].src +' ==> ' +sca['IP'].dst +' : '+ (sca['TLS']['TLS_Ext_ServerName'].servernames[0].servername).decode("utf-8")
        print(msg)
        
            
    #except:
    #    pass
    
    pkt.accept()

nfqueue = NetfilterQueue()
nfqueue.bind(1, print_and_accept)
try:
    nfqueue.run()
except KeyboardInterrupt:
    print('')

nfqueue.unbind()
