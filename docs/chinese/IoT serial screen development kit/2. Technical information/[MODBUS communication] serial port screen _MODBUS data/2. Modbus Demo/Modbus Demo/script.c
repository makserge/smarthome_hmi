////////////////////////////////////////////////////////////
///                                                      ///
///                    ��ע�����                      ///
///    ���ļ��е����к�����Ϊ�ص����������������ض���    ///
///    ʱ��ڵ㱻���á����ļ��в���������ӡ��޸ĺ���    ///
///    ������ӡ��޸ĺ�������,����޸ĵĺ����Ͳ�����     ///
///    ��Ч��                                            ///
///                                    2018-03-01        ///
////////////////////////////////////////////////////////////

/*
������on_init
���ܣ�ϵͳִ�г�ʼ��
*/
void on_init()
{
	//�������ϵ��ִ�еĲ���
}

/*
������on_systick
���ܣ�����ִ������(1��/��)
*/
void on_systick()
{
	//����������ʱÿ��ִ��һ��

}

/*
������on_timer
���ܣ���ʱ����ʱ֪ͨ
������timer_id����ʱ��ID
��ز�����
������ʱ����start_timer(timer_id,timeout,countdown,repeat)
            timer_id-��ʱ��ID��0~9��
			timeout-��ʱʱ�䣬���뵥λ
			countdown-0˳��ʱ��1����ʱ������sys.timer������ݼ�
			repeat-�ظ�������0��ʾ����
ֹͣ��ʱ����stop_timer(timer_id)
��ʱ����ֵ��sys.timer0~sys.timer9�����뵥λ
*/
void on_timer(int timer_id)
{
}

/*
������on_variant_upate
���ܣ�����ͨ�ŵ��±�������ʱ��ִ�д˺���
*/
void on_variant_upate()
{
	//������'@'�����ж�ĳ���Ĵ����Ƿ����ı�
	//����RTCʱ��
	if(@"���±��")
	{
		set_date("����ʱ��"[0],"����ʱ��"[1],"����ʱ��"[2]);
		set_time("����ʱ��"[3],"����ʱ��"[4],"����ʱ��"[5]);
	}
	

	//�����ԡ������仯ʱ���޸�����ϵͳ����
	if(@"����")
	{
		sys.lang = "����";
	}
	
}

/*
������on_control_notify
���ܣ��ؼ�ֵ����֪ͨ
������screen_id������ID
������control_id���ؼ�ID
������value����ֵ
*/
void on_control_notify(int screen_id,int control_id,int value)
{
	int i;
	if(screen_id == 19)
	{
		//������ʾ����
		if(control_id == 5 && value == 1)
		{	
			//����
			for(i = 7; i <=19; ++i)
			{
				hide(19, i);
			}
		}
		else if(control_id == 6 && value == 1)
		{	
			//��ʾ
			for(i = 7; i <=19; ++i)
			{
				show(19, i);
			}
		}
	}
}

/*
������on_screen_change
���ܣ������л�֪ͨ����ǰ����ID�����仯ʱִ�д˺���
������screen_id����ǰ����ID
*/
void on_screen_change(int screen_id)
{
}

