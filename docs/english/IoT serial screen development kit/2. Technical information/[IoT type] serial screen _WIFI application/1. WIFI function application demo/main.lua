local ssid = 0
local cjson = require "cjson"
local ahcp_n = '启用'
local network_cfg = {}
local u_dir = "b:/"
local surface = 0

local draw = 0
--初始化函数
function on_init()
    wifimode,secumode,ssid,password = get_wifi_cfg()
	set_text(1,4,ssid)
	set_text(1,5,password)
end

function on_systick()

    wifi_connect = get_network_state() --获取网络状态
	wifimode,secumode,ssid,password = get_wifi_cfg() --获取WIFI配置
	local dhcp, ipaddr, netmask, gateway, dns = get_network_cfg()

	if string.len(ssid)>0
	then
      if wifi_connect~=0
	  then
        set_text(1,1,' 连接'..ssid.."成功") 
		set_text(1,3,ssid)
		 set_text(1,2,ipaddr)
      else	  
	    set_text(1,1,' 连接'..ssid.."中...")
	  end
    else
	  set_text(1,1,'未连接')
	end	
end

--扫描wifi与显示
function scan_ap_fill_list()
    ap_cnt = scan_ap()  --扫描可用热点
	  
	for i=1,ap_cnt do
	  ssid,security,quality = get_ap_info(i-1)  --获取信息
	  set_text(2,i,ssid)  --显示id
	end
	
	for i=ap_cnt,10 do
	   set_text(2,i,"")  --清空后面的
	end
end

--控制控件
function on_control_notify(screen,control,value)  
	 --点击扫描热点
	if screen==1 and control==7 or 
	   screen==2 and control==21
	then
	    scan_ap_fill_list()
	end
	  
	if screen==1 and control==8 and value == 1  --保存设置
	then
	   ssid = get_text(1,4)
	   psw = get_text(1,5)  
	   set_wifi_cfg(1,0,ssid,psw) --1网卡模式，0自动识别加密
	   save_network_cfg();
	   set_text(1,1,' 连接中'..ssid.."...")
	end	
	 --选取热点
	if screen==2 and control>=11 and control<=20 and value == 1 
	then
	    ssid = get_text(2,(control-10)) --文本控件从1~10
		set_text(1,4,ssid)
	end
	if screen==3 and control==20 and value == 1 then
	    --获取公网入口IP地址
	   http_request(1000,'http://ip.taobao.com/service/getIpInfo.php?ip=myip',0)
 	   
		set_text(3,21,'wait http response...')
	end
	
	--使用HTTP协议从服务器下载文件
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
				if network_cfg[1] == "禁用" then
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

--系统回调http响应，
function on_http_response(taskid,resp)
   set_text(3,21,resp) --响应信息在文本控件上显示
      
   local jsdata = cjson.decode(resp) 
   local region = jsdata['data']['region']
  local city = jsdata['data']['city']
   
   set_text(3,22,region..'/'..city)
   
   --返回-1时，响应数据会通过串口发送给用户MCU
   return -1
end

function on_screen_change(screen)
    
	if screen==5
	then
		local dhcp, ipaddr, netmask, gateway, dns = get_network_cfg()
		if dhcp == 1 then
			ahcp_n = "启用"
		else
			ahcp_n = "禁用"
		end 
		set_text(5,1,ahcp_n)                                                  
		set_text(5,2,ipaddr)  
		set_text(5,3,gateway)  
		set_text(5,4,netmask)  
		set_text(5,5,dns)  
		ahcp_n = get_text(5,1) 
		if ahcp_n == "启用"  then
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
function on_usb_inserted(dir)                                  -- U盘函数
    u_dir = dir                                                --U盘路径
end

function on_draw(screen)
     if screen == 4 then
		 draw_surface(surface,180,135,430,350)
	 end
end
function on_usb_removed()
   u_dir = "b:/"
end
