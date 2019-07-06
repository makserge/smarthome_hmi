sn_counter = 0
local dev_status = {}
local meter_value = 0
local meter_flag = 0
flag = 0
--��ʼ���豸״̬
function init_dev_status()
    for i=0,16 do
	  dev_status[i] = 0
	end
end

--��ȡ�����Ƶ����ò���
--һ��ֻ��Ҫ�޸Ĳ�Ʒ��Կ
function gagent_get_info()  
  product_key = '1cc8b199a4c14a5f957e03340b9962b3'
  protocol_ver = '00000001'
  p0_ver = '00000002'
  hard_ver = '00000003'
  soft_ver = '00000004'  
  return product_key,protocol_ver,p0_ver,hard_ver,soft_ver
end

--
function on_systick()
    state,process = get_upgrade_state()                                     --��ȡ����״̬�����
    if state ~= 0
      then
          set_value(23,1,process)                                           --���ý�����
 		  set_value(23,3,process)                                           --������ֵ 
      end
      
    set_value(23,2,state)                                                   --����״̬��ʾ
	
    wifi_connect = get_network_state()                                      --��ȡ����״̬
	if wifi_connect~=0
	then
      set_text(19,1,'���ӳɹ�')             
	end
	
	--��ʾ��ǰ���ӵ�WIFI
	wifimode,secumode,ssid,password = get_wifi_cfg()                       --��ȡWIFI����
	dhcp,ipaddr = get_network_cfg()                                        --��ȡ��������
	 
	if wifi_connect>0
	then
	   set_text(19,3,ssid)                                                 --��ʾWIFI��Ϣ
	   set_text(19,2,ipaddr)
	else
       set_text(19,3,' ')
	   set_text(19,2,' ')	   
	end		
end

--�ƶ˿��ơ�APP��ʾ���Ŀؼ�
function update_cloud_ui()
    local status = dev_status[0]*256+dev_status[1]                         --��ȡ��ֵ
    switch =  (status&0x0001)
	switch_plasma =  (status&0x0002)
	led_air_quality =  (status&0x0004)
	child_security_lock = (status&0x0008)
	wind_velocity = (status&0x0030)>>4
	air_sensitivity = (status&0x01C0)>>6
	
	set_value(20,1,switch)                                                 --���ƿؼ�
	set_value(20,2,switch_plasma)
	set_value(20,3,led_air_quality)
	set_value(20,4,child_security_lock)
	set_value(20,10,wind_velocity)
	
	filter_life = dev_status[2]
	set_value(20,11,filter_life)
	set_value(20,12,filter_life)
	
	week_repeat = dev_status[3]
	set_value(20,13,week_repeat)
	set_value(20,14,week_repeat)
	
	temprature = dev_status[4]*255+dev_status[5]
	temprature = temprature/10.0
	set_value(20,6,temprature)
	
	countdown_off_min = dev_status[6]*256+dev_status[7]
	set_value(20,16,countdown_off_min)	
end

--��ʼ������
function on_init()
    start_timer(0,30000,0,0)
	init_dev_status()
	update_cloud_ui()
end

--�����������ƶˣ�action�������ϱ�Ϊ4����ѯ����Ϊ3
function gagent_send_status(action)
    local sendbuf = {}
	--��ʼ��Ϊȫ0
	for i=0,17 do
	  sendbuf[i] = 0
	end
	
	sendbuf[0] = action
	
	--����豸״̬
	for i=0,16 do
	  sendbuf[i+1] = dev_status[i]
	end
	
	gagent_send_data(sendbuf)
end

--�����Ǳ�
function on_timer(timer_id)  
  if timer_id==0
  then
    gagent_send_status(4)                                                    --��ʱ�����ϱ�
  elseif timer_id==1
  then
    if meter_value <=0                                                       --С��0ʱ����ֵ��
  	then
  		meter_flag = 0
    end
    if meter_value >=260                                                     --����0ʱ����ֵ��
  	then
  		meter_flag = 1
    end
    if meter_flag  ==0
    then
    set_value(6,2,meter_value)                                               --ָ��ת��
	meter_value = meter_value+4                                              --��ֵ����
	end
	if meter_flag ==1
	then
	set_value(6,2,meter_value)                                               --ָ��ת��
	meter_value = meter_value-4                                              --��ֵ����
	end  
  end	
end

--ɨ��wifi����ʾ
function scan_ap_fill_list()
    ap_cnt = scan_ap()                                                       --ɨ������ȵ�
	  
	for i=1,ap_cnt do
	  ssid,security,quality = get_ap_info(i-1)                               --��ȡ��Ϣ
	  set_text(21,i,ssid)                                                    --��ʾid
	end
	
	for i=ap_cnt,10 do
	   set_text(21,i,"")                                                     --��պ����
	end
end

--�����ƶˡ�app��ʾ���Ŀؼ�
function on_conctrol_notify_cloud(screen,control,value)
	local notify = 0
	local status_mask = 0
	local status_value = 0	
    
	--���ÿ���λ
	if control>=1 and control<=4                                             --����ť��ֵ��Ϊ1ʱ����Ӧλ��1��0ʱ����0����������λ��ֵ
	then
	  status_mask = 1<<(control-1)
	  if value>0                                                
	  then
         status_value = status_mask
	  end
	  dev_status[1] = dev_status[1]&(~status_mask)                           --��Ӧλ��0
	  dev_status[1] = dev_status[1]|status_value                             --��Ӧλ��1
	  notify = 1
	end
	
	--wind_velocity�����٣�
	if control==9
	then
	  status_mask = 0x30                                                     --5��6λ��1
	  status_value = value<<4                                   
	  dev_status[1] = dev_status[1]&(~status_mask)                           --��Ӧλ��0
	  dev_status[1] = dev_status[1]|status_value                             --��Ӧλ��1
	  notify = 1
	end
	
	--���ƻ���
	if control==12    
	then
      dev_status[2] = value&0xff
	  notify = 1
	end

	--���ƻ���
	if control==14
	then
	  dev_status[3] = value&0xff
	  notify = 1
	end

    --���ƻ���
    if control==16
	then
	  dev_status[6] = (value>>8)&0xff
	  dev_status[7] = value&0xff
	  notify = 1
	end
    
	--�����¶�
	temprature = dev_status[4]*255+dev_status[5]                             --��ȡ�ƶ˵��¶���ֵ
	temprature = temprature/10                               
    if control==5 and temprature>1                                           --��
    then
	  temprature = temprature-1                              
	  set_value(20,6,temprature)
	  
	  temprature = temprature*10                             
	  dev_status[4] = (temprature>>8)&0xff                                   --����
	  dev_status[5] = temprature&0xff
	  notify = 1
    end	
	
	if control==7 and temprature<35                                         --��
    then
	  temprature = temprature+1
	  set_value(20,6,temprature)
	  
	  temprature = temprature*10
	  dev_status[4] = (temprature>>8)&0xff                                   --��䷵������
	  dev_status[5] = temprature&0xff	  
	  notify = 1
    end
	
	if notify>0
	then
	  gagent_send_status(4)                                                  --����
	end
end

--���ƿؼ�
function on_control_notify(screen,control,value) 
    if screen==5                                                             --������
    then
        if control==3 and value > 0                                                       --�ؼ�������
        then
		    value=get_value(5,1)                             
            if value>0 
            then
            value=value-5
            end
             if value<0 
            then
            value=0
            end
 		    set_value(5,1,value)                                                 --������ֵ
            set_value(5,2,value)	
         end
         if control==4 and value > 0                                                      --�ؼ����ӡ�
         then
 	         value=get_value(5,1)
             if value<100
             then
             value=value+5
             end
             if value>100
             then
             value=100
             end
 		 	 set_value(5,1,value)                                                 --������ֵ
             set_value(5,2,value) 
        end
	    if control==1                                                        --ֱ�ӵ��������
	    then
            value=value
 		    set_value(5,1,value)                                                 --������ֵ
            set_value(5,2,value)	
	    end  
    end
    
	if 	screen==6 and control==1 and value == 1                              --�����Ǳ�ָ��
	then
		start_timer(1,1,0,0)                                                 --������ʱ����20��������
  	end
  	if 	screen==6 and control==1 and value == 0                              --ȡ�������Ǳ�ָ��
	then
		stop_timer(1) 
  	end
	 if screen==7 and control==2                                             --������ڱ���
	 then	 
        set_value(7,3,value)                                                 --�޸Ľ�����
        set_backlight(value)		
	 end	
	
	if screen==18 and control==5                                             --�����ַ���ʱ����ͣ����
	then
		play_sound('0')
		set_value(18,3,0)
 		set_value(18,4,0)	
	end

	 if screen==23 and control==4                                            --Զ������
	  then
	    start_upgrade('ftp://192.168.0.2/DCIOT.PKG')
	  end
	  
	 --���ɨ���ȵ�
	 if screen==19 and control==7 or 
	    screen==21 and control==21
	  then
	    scan_ap_fill_list()
	  end
	  
	 if screen==19 and control==8                                           --��������
	 then
	   ssid = get_text(19,4)
	   psw = get_text(19,5)
	   set_wifi_cfg(1,0,ssid,psw)                                           --1����ģʽ��0�Զ�ʶ�����
	   save_network_cfg();
	   set_text(19,1,'������...')
	 end  
	 
	 --ѡȡ�ȵ�
	 if screen==21 and control>=11 and control<=20
	 then
	    ssid = get_text(screen,control-10)                                  --�ı��ؼ���1~10
		set_text(19,4,ssid)
	 end
	 
	 if screen==20                                                          --����app��ʾҳ�棬���뺯��
	 then
	    on_conctrol_notify_cloud(screen,control,value)
	 end
end

function on_screen_change(screen)
	
	if screen==17                                                           --�ڽ�����Ƶҳ��ʱ�����ż����ǰ���״̬�����������ǵ���
	then
			set_text_roll(17,5,110)                                         --���ֹ���
			set_value(17,1,1)                                               --���ż�����
 			set_value(17,2,0)                                               --��ͣ������
			set_value(17,3,0)                                               --ֹͣ������
	end

	--�л�����������ҳ��
	if screen==19
	then
		wifimode,secumode,ssid,password = get_wifi_cfg()                        --��ȡ������Ϣ
		set_text(19,4,ssid)                                                     --д��
	end
  
	--���ö�ά��Ϊ�����ư�URL
	if screen==20
	then	
		bind_url = gagent_get_bind_url()                                        --��ȡ��ά��
		set_text(20,17,bind_url)                                                --���ö�ά��
	end
end

--��when>0ʱ������value�Ķ��λ
function set_bits_when(value,bitmask,bitvalue,when)
   if when>0
   then
     value = value&(~bitmask) --clear bits
	 bitvalue = bitvalue&bitmask
     value = value|bitvalue --set bits
	 print(value)
    end
	return value
end

--MCU�����ƶ�
function gagent_wifi_ctrl_mcu(packet)
    local attr_flags = packet[1]*256+packet[2]	
	local value = packet[3]*256+packet[4]	
	local status = dev_status[0]*256+dev_status[1]
	
	--print('attr,value,status')
	--print(attr_flags)
	--print(value)
    
	status = set_bits_when(status,0x0001,value,attr_flags&0x01)             --switch
	status = set_bits_when(status,0x0002,value,attr_flags&0x02)             --switch_plasma
	status = set_bits_when(status,0x0004,value,attr_flags&0x04)             --led_ari_qulity
	status = set_bits_when(status,0x0008,value,attr_flags&0x08)             --child_security_lock
	status = set_bits_when(status,0x0030,value,attr_flags&0x10)             --wind_velocity
	status = set_bits_when(status,0x01C0,value,attr_flags&0x20)             --air_sensitivity
	
	dev_status[0] = (status>>8)&0xff
	dev_status[1] = (status&0xff)                                           --����ͷ���
	--print(status)
	
	--filter life
	if (attr_flags&0x40)>0
	then 
	  dev_status[2] = packet[5]                                             --����
	end	
	
	--week repeat
	if (attr_flags&0x80)>0
	then 
	  dev_status[3] = packet[6]                                             --����
	end	
	
	--coutdwon on min                                
	if (attr_flags&0x100)>0
	then 
	  dev_status[4] = packet[7]                                            --�¶�
	  dev_status[5] = packet[8]
	end	
	
	--coutdown off min                               
	if (attr_flags&0x200)>0
	then 
	  dev_status[6] = packet[9]                                            --����
	  dev_status[7] = packet[10]
	end

	--time on
    if (attr_flags&0x400)>0                          
	then 
	  dev_status[8] = packet[11]                                           --��ʱ
	  dev_status[9] = packet[12]
	end

	--time off
    if (attr_flags&0x800)>0
	then 
	  dev_status[10] = packet[13]                                          --��ʱ
	  dev_status[11] = packet[14]
	end	
    
	--���������ϱ�״̬
    gagent_send_status(4)   	
end

--�����յ������Ʒ��͵���Ϣʱ,
--ϵͳ�Զ����ô˺�����packetΪ��Ϣ�ֽ�����
--δ����˺��������ߺ�������0ʱ��
--����Ϣ��ͨ�����ڷ��͵��û���MCU
--����1ʱ�������Ƶ���Ϣ�������û���MCU
function on_gagent_recv_data(packet)
    --��ӡ��Ϣ
    print('on_gagent_recv_data:')
    for i=0,#(packet) do
	  print(packet[i])
	end
	
	--action�����жϱ�������
	action = packet[0]	
	
	--WIFIģ������豸
	if action==0x01
	then
	  gagent_wifi_ctrl_mcu(packet)                                        --�����������
	  update_cloud_ui()                                                   --���½�����ʾ
	end
	
	--WIFIģ���ȡ�豸״̬
	if action==0x02
	then
	  gagent_send_status(3)
	end
	
	--����1����Ϣ����Ҫ�����û�MCU
    return 1	
end