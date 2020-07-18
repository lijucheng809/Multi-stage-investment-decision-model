math.randomseed(tostring(os.time()):reverse():sub(1, 7))
CPr_distribution={}
CPr_distribution.__index=CPr_distribution

function Random_Normal_distribution()  --   获取标准正态分布随机数
    local u = math.random()
    local v = math.random()
    local  z = math.sqrt(-2 * math.log(u)) * math.cos( 2 * math.pi * v)
    return z
end

function CPr_distribution:new(q,k,t,T,stand_dev,u,p)---q指需求列表，k指货物种类，t指具体哪个时期,stand_dev指标准差列表,u指增长率列表
    setmetatable (CPr_distribution,self)
    self.q={}
    self.q_new={}                                                 --存放下一阶段的需求列表
    self.k=k
    self.t=t
    self.p_marg={}                                                --存放边际概率
    self.p_jon={}                                                 --存放联合概率
    self.stand_dev={}
    self.T=T
    self.u={}
    self.num=3 
    self.q_01={}
    self.p=p                                                     --存放最终概率
    
    --for i=1,self.k*self.t do
        --self.p[i]=p[i]
    --end
    for i=1,#q do
        self.q[i]=q[i]
        self.q_01[i]=0
        self.u[i]=u[i]
        self.stand_dev[i]=stand_dev[i]
        
    end
    --for i=1, self.k*self.T+4*self.T+self.k*self.t do
        --self.stand_dev[i]=stand_dev[i]
    --end
    return self
end

function CPr_distribution:p_of_marg()
    local count_1={}  --统计需求上涨次数
    local count_2={}  --统计需求下降次数
    local count_3={}  --统计需求不变次数
    for i=1,self.k do
        count_1[i]=0
        count_2[i]=0
        --count_3[i]=0
    end
    for count=1,1000 do
        for i=1,self.k do
            local  q_temp=self.q[i]
           
            for ix=1, 12 do
                local ε=Random_Normal_distribution()
                q_temp=q_temp*math.exp((self.u[i]-0.5*self.stand_dev[i]*stand_dev[i])/12+self.stand_dev[i]*ε*math.sqrt(1/12))
            end
           -- print(q_temp)
            if q_temp>self.q[i] then
                count_1[i]=count_1[i]+1
            end
            if q_temp<self.q[i] then
                count_2[i]=count_2[i]+1
            end
            --if q_temp==self.q[i] then
                --count_3[i]=count_3[i]+1
            --end
        end
    end
    for i=1,self.k do
        self.p_marg[i]={}
        self.p_marg[i][1]=count_1[i]/1000
        self.p_marg[i][2]=count_2[i]/1000
        --print("count_1 ",i,"is:",count_1[i])
        --print("count_2 ",i,"is:",count_2[i])
        --self.p_marg[i][3]=count_3[i]/1000
    end
    --print(self.p_marg[3][1],' ',self.p_marg[3][2],' ' )
end




function CPr_distribution:move_01(num,r)                                   --01交换法
    for i=1,num do
        if self.q_01[i]==0 then
            self.q_01[i]=1
            if self.q_new[self.num][i]==self.q[i]+self.stand_dev[i] then
                self.q_new[self.num][i]=self.q[i]-self.stand_dev[i]
                self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[i][1]*self.p_marg[i][2]
                
            else
                self.q_new[self.num][i]=self.q[i]+self.stand_dev[i]
                self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[i][2]*self.p_marg[i][1]
            end
        end
    end
    
    for i=num+1, r do
        if self.q_01[i]==1 then
            self.q_01[i]=0
            if self.q_new[self.num][i]==self.q[i]+self.stand_dev[i] then
                self.q_new[self.num][i]=self.q[i]-self.stand_dev[i]
                self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[i][1]*self.p_marg[i][2]
                
            else
                self.q_new[self.num][i]=self.q[i]+self.stand_dev[i]
                self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[i][2]*self.p_marg[i][1]
            end
        end
    end
    self.num=self.num+1
    self.q_new[self.num]={}
    for i=1,self.k do
        self.q_new[self.num][i]=self.q_new[self.num-1][i]
        self.p_jon[self.num]=self.p_jon[self.num-1]
    end
end

function CPr_distribution:comb_01(q,Len,k,p)                               --01交换法
    local tag={q_new={},q_01={}}
    self.q_new[self.num]={}
    for i=1,Len do
        tag.q_new[i]=q[i]
        self.q_new[self.num][i]=q[i]
        self.q_01[i]=0
    end
    self.p_jon[self.num]=p
    for i=1, k do
        self.q_01[i]=1
    end
    if tag.q_new[1]==self.q[1]+self.stand_dev[1] then
        for i=1,k do
            self.q_new[self.num][i]=self.q[i]-self.stand_dev[i]
            self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[i][1]*self.p_marg[i][2]
        end
        self.num=self.num+1
        self.q_new[self.num]={}
        for i=1,Len do
            self.q_new[self.num][i]=self.q_new[self.num-1][i]
            self.p_jon[self.num]=self.p_jon[self.num-1]
        end
        
    else
        for i=1,k do
            self.q_new[self.num][i]=self.q[i]+self.stand_dev[i]
            self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[i][2]*self.p_marg[i][1]
        end
        self.num=self.num+1
        self.q_new[self.num]={}
        for i=1,Len do
            self.q_new[self.num][i]=self.q_new[self.num-1][i]
            self.p_jon[self.num]=self.p_jon[self.num-1]
        end
    end
    while true do
        local j=1
        local tips=1
        local b
        while j <Len do
            if self.q_01[j]==1 then
                tips=tips+1
                if self.q_01[j+1]==0 then
                    self.q_01[j]=0
                    self.q_01[j+1]=1
                    if self.q_new[self.num][j]==self.q[j]+self.stand_dev[j] then
                        self.q_new[self.num][j]=self.q[j]-self.stand_dev[j]
                        self.q_new[self.num][j+1]=self.q[j+1]+self.stand_dev[j+1]
                        self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[j][1]*self.p_marg[j][2]/self.p_marg[j+1][2]*self.p_marg[j+1][1]
                    else    
                        self.q_new[self.num][j]=self.q[j]+self.stand_dev[j]
                        self.q_new[self.num][j+1]=self.q[j+1]-self.stand_dev[j+1]
                        self.p_jon[self.num]=self.p_jon[self.num]/self.p_marg[j][2]*self.p_marg[j][1]/self.p_marg[j+1][1]*self.p_marg[j+1][2]
                    end
                    CPr_distribution:move_01(tips-2,j-1)
                    break
                end
            end
            j=j+1
        end
        if j==Len then
            break
        end
    end
    
end

function CPr_distribution:p_of_jonit()                                      --求联合概率
    self.q_new[1]={}
    self.q_new[2]={}
    self.p_jon[1]=1
    self.p_jon[2]=1
    local tag={q_new={},p_jon={},num=0,t}
    for i=1,self.k do
        self.q_new[1][i]=self.q[i]+self.stand_dev[i]
        self.p_jon[1]=self.p_jon[1]*self.p_marg[i][1]
        self.q_new[2][i]=self.q[i]-self.stand_dev[i]
        self.p_jon[2]=self.p_jon[2]*self.p_marg[i][2]
    end
    if self.k%2~=0 then
        for i=1, self.k/2 do
            CPr_distribution:comb_01(self.q_new[1],self.k,i,self.p_jon[1])
            CPr_distribution:comb_01(self.q_new[2],self.k,i,self.p_jon[2])
        end
    else 
        for i=1, self.k/2-1 do
            CPr_distribution:comb_01(self.q_new[1],self.k,i,self.p_jon[1])
            CPr_distribution:comb_01(self.q_new[2],self.k,i,self.p_jon[2])
            
        end  
        CPr_distribution:comb_01(self.q_new[1],self.k,self.k/2,self.p_jon[1])
    end
    self.num=self.num-1
    for i=1,self.num do
        tag.q_new[i]={}
        for j=1,self.k do
            tag.q_new[i][j]=self.q_new[i][j]
        end
        --tag.p_jon[i]=self.p_jon[i]
        tag.p_jon[i]=self.p_jon[i]*self.p
    end
    
    tag.num=self.num
    tag.t=self.t+1
    return tag
end
--[[
q={1.50690,5.70700,10.39400}
k=3
t=1
T=5
stand_dev={0.22834,0.52741,1.86766}
u={0.0626,0.0163,0.0533}

a=Get_p:new(q,k,t,T,stand_dev,u)
--debug.debug()
b=a:p_of_marg()
c=a:p_of_jonit()
abc=0
for i=1,c.num do
    abc=abc+c.p_jon[i]
end
--print('xxx',abc)
--abc=1*math.exp(-2225.4873230902 )
--print(abc,' xxx')
--]]