from netfilterqueue import NetfilterQueue
from scapy.all import *

sni_black_list = [ 
'www.uniroma2.it',
'esamionline.uniroma2.it',
'www.shorturl.at',
'play.google.com'
] 
 

def print_and_accept(pkt):
    load_layer("tls")
    #print(pkt)
    sca = IP(pkt.get_payload())
    #print (sca['IP'].src)
    #try:


    if sca.haslayer('TLS') and sca['TLS'].type == 22 and sca['TLS'].msg[0].msgtype == 1:
        
        msg = sca['IP'].src +' ==> ' +sca['IP'].dst +' : '+ (sca['TLS']['TLS_Ext_ServerName'].servernames[0].servername).decode("utf-8")
        #print(msg)
        sni = (sca['TLS']['TLS_Ext_ServerName'].servernames[0].servername).decode("utf-8")
        if (sni in sni_black_list) :
            pkt.drop() 
            print('DROP: '+sni)
        else :
            print('ACCEPT: '+sni)
            pkt.accept()    
                    
    else :
            
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
