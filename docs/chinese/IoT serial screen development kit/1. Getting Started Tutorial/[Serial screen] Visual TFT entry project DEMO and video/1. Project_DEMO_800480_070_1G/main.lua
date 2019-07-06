sn_counter = 0
local dev_status = {}
local meter_value = 0
local meter_flag = 0
flag = 0
--初始化设备状态
function init_dev_status()
    for i=0,16 do
	  dev_status[i] = 0
	end
end

--获取机智云的配置参数
--一般只需要修改产品密钥
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
    state,process = get_upgrade_state()                                     --获取更新状态与进度
    if state ~= 0
      then
          set_value(23,1,process)                                           --设置进度条
 		  set_value(23,3,process)                                           --设置数值 
      end
      
    set_value(23,2,state)                                                   --升级状态提示
	
    wifi_connect = get_network_state()                                      --获取网络状态
	if wifi_connect~=0
	then
      set_text(19,1,'连接成功')             
	end
	
	--显示当前连接的WIFI
	wifimode,secumode,ssid,password = get_wifi_cfg()                       --获取WIFI配置
	dhcp,ipaddr = get_network_cfg()                                        --获取网络配置
	 
	if wifi_connect>0
	then
	   set_text(19,3,ssid)                                                 --显示WIFI信息
	   set_text(19,2,ipaddr)
	else
       set_text(19,3,' ')
	   set_text(19,2,' ')	   
	end		
end

--云端控制“APP演示”的控件
function update_cloud_ui()
    local status = dev_status[0]*256+dev_status[1]                         --获取数值
    switch =  (status&0x0001)
	switch_plasma =  (status&0x0002)
	led_air_quality =  (status&0x0004)
	child_security_lock = (status&0x0008)
	wind_velocity = (status&0x0030)>>4
	air_sensitivity = (status&0x01C0)>>6
	
	set_value(20,1,switch)                                                 --控制控件
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

--初始化函数
function on_init()
    start_timer(0,30000,0,0)
	init_dev_status()
	update_cloud_ui()
end

--发送数据至云端；action，主动上报为4，查询反馈为3
function gagent_send_status(action)
    local sendbuf = {}
	--初始化为全0
	for i=0,17 do
	  sendbuf[i] = 0
	end
	
	sendbuf[0] = action
	
	--填充设备状态
	for i=0,16 do
	  sendbuf[i+1] = dev_status[i]
	end
	
	gagent_send_data(sendbuf)
end

--控制仪表
function on_timer(timer_id)  
  if timer_id==0
  then
    gagent_send_status(4)                                                    --定时主动上报
  elseif timer_id==1
  then
    if meter_value <=0                                                       --小于0时，数值加
  	then
  		meter_flag = 0
    end
    if meter_value >=260                                                     --大于0时，数值减
  	then
  		meter_flag = 1
    end
    if meter_flag  ==0
    then
    set_value(6,2,meter_value)                                               --指针转动
	meter_value = meter_value+4                                              --数值增加
	end
	if meter_flag ==1
	then
	set_value(6,2,meter_value)                                               --指针转动
	meter_value = meter_value-4                                              --数值增加
	end  
  end	
end

--扫描wifi与显示
function scan_ap_fill_list()
    ap_cnt = scan_ap()                                                       --扫描可用热点
	  
	for i=1,ap_cnt do
	  ssid,security,quality = get_ap_info(i-1)                               --获取信息
	  set_text(21,i,ssid)                                                    --显示id
	end
	
	for i=ap_cnt,10 do
	   set_text(21,i,"")                                                     --清空后面的
	end
end

--控制云端“app演示”的控件
function on_conctrol_notify_cloud(screen,control,value)
	local notify = 0
	local status_mask = 0
	local status_value = 0	
    
	--设置开关位
	if control>=1 and control<=4                                             --当按钮的值变为1时，对应位置1；0时，置0；保留其他位的值
	then
	  status_mask = 1<<(control-1)
	  if value>0                                                
	  then
         status_value = status_mask
	  end
	  dev_status[1] = dev_status[1]&(~status_mask)                           --对应位置0
	  dev_status[1] = dev_status[1]|status_value                             --对应位置1
	  notify = 1
	end
	
	--wind_velocity（风速）
	if control==9
	then
	  status_mask = 0x30                                                     --5、6位置1
	  status_value = value<<4                                   
	  dev_status[1] = dev_status[1]&(~status_mask)                           --对应位置0
	  dev_status[1] = dev_status[1]|status_value                             --对应位置1
	  notify = 1
	end
	
	--控制滑块
	if control==12    
	then
      dev_status[2] = value&0xff
	  notify = 1
	end

	--控制滑块
	if control==14
	then
	  dev_status[3] = value&0xff
	  notify = 1
	end

    --控制滑块
    if control==16
	then
	  dev_status[6] = (value>>8)&0xff
	  dev_status[7] = value&0xff
	  notify = 1
	end
    
	--控制温度
	temprature = dev_status[4]*255+dev_status[5]                             --获取云端的温度数值
	temprature = temprature/10                               
    if control==5 and temprature>1                                           --减
    then
	  temprature = temprature-1                              
	  set_value(20,6,temprature)
	  
	  temprature = temprature*10                             
	  dev_status[4] = (temprature>>8)&0xff                                   --返回
	  dev_status[5] = temprature&0xff
	  notify = 1
    end	
	
	if control==7 and temprature<35                                         --加
    then
	  temprature = temprature+1
	  set_value(20,6,temprature)
	  
	  temprature = temprature*10
	  dev_status[4] = (temprature>>8)&0xff                                   --填充返回数据
	  dev_status[5] = temprature&0xff	  
	  notify = 1
    end
	
	if notify>0
	then
	  gagent_send_status(4)                                                  --发送
	end
end

--控制控件
function on_control_notify(screen,control,value) 
    if screen==5                                                             --进度条
    then
        if control==3 and value > 0                                                       --控件‘减’
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
 		    set_value(5,1,value)                                                 --设置数值
            set_value(5,2,value)	
         end
         if control==4 and value > 0                                                      --控件‘加’
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
 		 	 set_value(5,1,value)                                                 --设置数值
             set_value(5,2,value) 
        end
	    if control==1                                                        --直接点击进度条
	    then
            value=value
 		    set_value(5,1,value)                                                 --设置数值
            set_value(5,2,value)	
	    end  
    end
    
	if 	screen==6 and control==1 and value == 1                              --控制仪表指针
	then
		start_timer(1,1,0,0)                                                 --启动定时器，20毫秒周期
  	end
  	if 	screen==6 and control==1 and value == 0                              --取消控制仪表指针
	then
		stop_timer(1) 
  	end
	 if screen==7 and control==2                                             --滑块调节背光
	 then	 
        set_value(7,3,value)                                                 --修改进度条
        set_backlight(value)		
	 end	
	
	if screen==18 and control==5                                             --从音乐返回时，暂停音乐
	then
		play_sound('0')
		set_value(18,3,0)
 		set_value(18,4,0)	
	end

	 if screen==23 and control==4                                            --远程升级
	  then
	    start_upgrade('ftp://192.168.0.2/DCIOT.PKG')
	  end
	  
	 --点击扫描热点
	 if screen==19 and control==7 or 
	    screen==21 and control==21
	  then
	    scan_ap_fill_list()
	  end
	  
	 if screen==19 and control==8                                           --保存设置
	 then
	   ssid = get_text(19,4)
	   psw = get_text(19,5)
	   set_wifi_cfg(1,0,ssid,psw)                                           --1网卡模式，0自动识别加密
	   save_network_cfg();
	   set_text(19,1,'连接中...')
	 end  
	 
	 --选取热点
	 if screen==21 and control>=11 and control<=20
	 then
	    ssid = get_text(screen,control-10)                                  --文本控件从1~10
		set_text(19,4,ssid)
	 end
	 
	 if screen==20                                                          --进入app演示页面，进入函数
	 then
	    on_conctrol_notify_cloud(screen,control,value)
	 end
end

function on_screen_change(screen)
	
	if screen==17                                                           --在进入视频页面时，播放键总是按下状态，其它键总是弹起
	then
			set_text_roll(17,5,110)                                         --文字滚动
			set_value(17,1,1)                                               --播放键按下
 			set_value(17,2,0)                                               --暂停键按下
			set_value(17,3,0)                                               --停止键弹起
	end

	--切换到网络设置页面
	if screen==19
	then
		wifimode,secumode,ssid,password = get_wifi_cfg()                        --获取网络信息
		set_text(19,4,ssid)                                                     --写入
	end
  
	--设置二维码为机智云绑定URL
	if screen==20
	then	
		bind_url = gagent_get_bind_url()                                        --获取二维码
		set_text(20,17,bind_url)                                                --设置二维码
	end
end

--当when>0时，设置value的多个位
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

--MCU控制云端
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
	dev_status[1] = (status&0xff)                                           --开光和风速
	--print(status)
	
	--filter life
	if (attr_flags&0x40)>0
	then 
	  dev_status[2] = packet[5]                                             --滑块
	end	
	
	--week repeat
	if (attr_flags&0x80)>0
	then 
	  dev_status[3] = packet[6]                                             --滑块
	end	
	
	--coutdwon on min                                
	if (attr_flags&0x100)>0
	then 
	  dev_status[4] = packet[7]                                            --温度
	  dev_status[5] = packet[8]
	end	
	
	--coutdown off min                               
	if (attr_flags&0x200)>0
	then 
	  dev_status[6] = packet[9]                                            --滑块
	  dev_status[7] = packet[10]
	end

	--time on
    if (attr_flags&0x400)>0                          
	then 
	  dev_status[8] = packet[11]                                           --定时
	  dev_status[9] = packet[12]
	end

	--time off
    if (attr_flags&0x800)>0
	then 
	  dev_status[10] = packet[13]                                          --定时
	  dev_status[11] = packet[14]
	end	
    
	--立即主动上报状态
    gagent_send_status(4)   	
end

--当接收到机智云发送的消息时,
--系统自动调用此函数，packet为消息字节数组
--未定义此函数，或者函数返回0时，
--此消息会通过串口发送到用户的MCU
--返回1时，机智云的消息不发给用户的MCU
function on_gagent_recv_data(packet)
    --打印消息
    print('on_gagent_recv_data:')
    for i=0,#(packet) do
	  print(packet[i])
	end
	
	--action用于判断报文作用
	action = packet[0]	
	
	--WIFI模块控制设备
	if action==0x01
	then
	  gagent_wifi_ctrl_mcu(packet)                                        --处理控制命令
	  update_cloud_ui()                                                   --更新界面显示
	end
	
	--WIFI模块读取设备状态
	if action==0x02
	then
	  gagent_send_status(3)
	end
	
	--返回1，消息不需要发给用户MCU
    return 1	
end