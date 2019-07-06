local ssid = 0
local cjson = require "cjson"
local ahcp_n = '����'
local network_cfg = {}
local u_dir = "b:/"
local surface = 0

local draw = 0
--��ʼ������
function on_init()
    wifimode,secumode,ssid,password = get_wifi_cfg()
	set_text(1,4,ssid)
	set_text(1,5,password)
end

function on_systick()

    wifi_connect = get_network_state() --��ȡ����״̬
	wifimode,secumode,ssid,password = get_wifi_cfg() --��ȡWIFI����
	local dhcp, ipaddr, netmask, gateway, dns = get_network_cfg()

	if string.len(ssid)>0
	then
      if wifi_connect~=0
	  then
        set_text(1,1,' ����'..ssid.."�ɹ�") 
		set_text(1,3,ssid)
		 set_text(1,2,ipaddr)
      else	  
	    set_text(1,1,' ����'..ssid.."��...")
	  end
    else
	  set_text(1,1,'δ����')
	end	
end

--ɨ��wifi����ʾ
function scan_ap_fill_list()
    ap_cnt = scan_ap()  --ɨ������ȵ�
	  
	for i=1,ap_cnt do
	  ssid,security,quality = get_ap_info(i-1)  --��ȡ��Ϣ
	  set_text(2,i,ssid)  --��ʾid
	end
	
	for i=ap_cnt,10 do
	   set_text(2,i,"")  --��պ����
	end
end

--���ƿؼ�
function on_control_notify(screen,control,value)  
	 --���ɨ���ȵ�
	if screen==1 and control==7 or 
	   screen==2 and control==21
	then
	    scan_ap_fill_list()
	end
	  
	if screen==1 and control==8 and value == 1  --��������
	then
	   ssid = get_text(1,4)
	   psw = get_text(1,5)  
	   set_wifi_cfg(1,0,ssid,psw) --1����ģʽ��0�Զ�ʶ�����
	   save_network_cfg();
	   set_text(1,1,' ������'..ssid.."...")
	end	
	 --ѡȡ�ȵ�
	if screen==2 and control>=11 and control<=20 and value == 1 
	then
	    ssid = get_text(2,(control-10)) --�ı��ؼ���1~10
		set_text(1,4,ssid)
	end
	if screen==3 and control==20 and value == 1 then
	    --��ȡ�������IP��ַ
	   http_request(1000,'http://ip.taobao.com/service/getIpInfo.php?ip=myip',0)
 	   
		set_text(3,21,'wait http response...')
	end
	
	--ʹ��HTTPЭ��ӷ����������ļ�
	 if screen==4 and control == 1                                                    
	    then
			http_download(1,'http://www.gz-dc.com/download/tuku/pic1.jpg',u_dir.."pic1.jpg")
 			set_value(4,4,0)	
			if surface ~= 0 then
			    destroy_surface(surface)
				surface = 0
			end
		end	
	if screen==4 and control == 2                                                   
	   then
		    http_download(2,'http://www.gz-dc.com/download/tuku/pic2.jpg',u_dir.."pic2.jpg")
 			set_value(4,4,0)	
 			if surface ~= 0 then
			    destroy_surface(surface)
				surface = 0
			end
		end	
	if  screen==5 and control == 13 then
		if value == 1  then
			for i = 1 ,4 do
				set_visiable(5,i+1,0)
				set_visiable(5,i+20,0)
			end
		else 
			for i = 1 ,4 do
				set_visiable(5,i+1,1)
				set_visiable(5,i+20,1)
			end
		end	
    end
	if screen==6 and control == 26  and value == 1                                           
	then
		for i = 1 ,5 do
			network_cfg[i] = get_text(3,i)
			if i == 1 then
				if network_cfg[1] == "����" then
					network_cfg[1] = 0
				else
					network_cfg[1] = 1
				end
			end
		end
		set_network_cfg(network_cfg[1],network_cfg[2],network_cfg[4],network_cfg[3],network_cfg[5])
		save_network_cfg()	
	end
end
function on_http_download (taskid, status)
	if taskid == 1 then
		if status == 0 then
			set_value(4,4,1)
		elseif status == 1 then
			set_value(4,4,2)
		elseif status == 2 then
			set_value(4,4,3)
			surface = load_surface(u_dir.."pic1.jpg")
			redraw()	
		end
	end
	if taskid == 2 then
		if status == 0 then
			set_value(4,4,1)
		elseif status == 1 then
			set_value(4,4,2)
		elseif status == 2 then
			set_value(4,4,3)
			surface = load_surface(u_dir.."pic2.jpg")
			redraw()	
		end
	end	
	
end

--ϵͳ�ص�http��Ӧ��
function on_http_response(taskid,resp)
   set_text(3,21,resp) --��Ӧ��Ϣ���ı��ؼ�����ʾ
      
   local jsdata = cjson.decode(resp) 
   local region = jsdata['data']['region']
  local city = jsdata['data']['city']
   
   set_text(3,22,region..'/'..city)
   
   --����-1ʱ����Ӧ���ݻ�ͨ�����ڷ��͸��û�MCU
   return -1
end

function on_screen_change(screen)
    
	if screen==5
	then
		local dhcp, ipaddr, netmask, gateway, dns = get_network_cfg()
		if dhcp == 1 then
			ahcp_n = "����"
		else
			ahcp_n = "����"
		end 
		set_text(5,1,ahcp_n)                                                  
		set_text(5,2,ipaddr)  
		set_text(5,3,gateway)  
		set_text(5,4,netmask)  
		set_text(5,5,dns)  
		ahcp_n = get_text(5,1) 
		if ahcp_n == "����"  then
			for i = 1 ,4 do
				set_visiable(5,i+1,0)
				set_visiable(5,i+20,0)
			end
		else 
			for i = 1 ,4 do
				set_visiable(5,i+1,1)
				set_visiable(5,i+20,1)
			end
		end	
	end
    if screen==4
	then
		set_value(4,4,0)
	end
end
function on_usb_inserted(dir)                                  -- U�̺���
    u_dir = dir                                                --U��·��
end

function on_draw(screen)
     if screen == 4 then
		 draw_surface(surface,180,135,430,350)
	 end
end
function on_usb_removed()
   u_dir = "b:/"
end
