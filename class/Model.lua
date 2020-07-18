Model={}
Model.__index=Model

function Model:new(k,t,q)
    setmetatable(Model,self)
    self.t=t             
    self.k=k
    self.q={}             --当前时期的各货物的需求量
    self.I=200000         --总投资
    ------泊位建设成本-------
    c={0.3,0.2}
    self.c={}
    for i=1,self.t*self.k do
        table.insert(self.c,c[1])
        table.insert(self.c,c[2])
    end
    ---第k种货物的设计吞吐量-----
    Q={0.28,0.33}
    self.Q={}
    for i=1,self.t*self.k do
        table.insert(self.Q,Q[1])
        table.insert(self.Q,Q[2])
    end
       
    self.b_0={1,10}             --初期泊位数
    self.r={}
    self.y={}
    for i=1,self.t do
        self.r[i]=0.03
        self.y[i]=0.7
    end
    self.a=2                           --冗余系数
    
     ------第k种泊位占用岸线长度为l_k-----------
    l_k={800,700}
    self.l_k={}
    for i=1,self.k*self.t do
        table.insert(self.l_k,l_k[1])
        table.insert(self.l_k,l_k[2])
    end
    
    self.R_space=120000
    --self.R={100000,20000,130,6000}       
    --self.R={75,12,0.01,4.5} 
    self.R={200,100,0.01,4.5} 
    --self.f={15000000,800000,2500000,7000000}
    self.f={1500,800,250,70}
    --self.f={150,80,250,70}
    
    
    n_air={4,3}
    n_water={1,0.5}
    n_solid={0.008,0.002}
    n_voice={0.2,0.2}
    self.n_air={}
    self.n_water={}
    self.n_solid={}
    self.n_voice={}
    for i=1,self.k*self.t do
        self.n_air[i]=0
        self.n_water[i]=0
        self.n_solid[i]=0
        self.n_voice[i]=0
    end
    for i=1,self.t do
        table.insert(self.n_air,n_air[1])
        table.insert(self.n_air,n_air[2])
        table.insert(self.n_water,n_water[1])
        table.insert(self.n_water,n_water[2])
        table.insert(self.n_solid,n_solid[1])
        table.insert(self.n_solid,n_solid[2])
        table.insert(self.n_voice,n_voice[1])
        table.insert(self.n_voice,n_voice[2])
    end
    --[[
    local temp=1
    for i=self.k*self.t+1,self.k*self.t*2 do
        table.insert(self.n_air,n_air[temp])
        table.insert(self.n_water,n_water[temp])
        table.insert(self.n_solid,n_solid[temp])
        table.insert(self.n_voice,n_voice[temp])
        temp=temp+1
    end--]]
    
    --self.p={20,35,20000,1000}                --在约束条件中存放资源费用
    self.p={2,3.5,2,1}
    

    p_b={5,6}
    self.p_b={}
    for i=1,self.k*self.t do
        self.p_b[i]=0
    end

    for i=1,self.t do
        table.insert(self.p_b,p_b[1])
        table.insert(self.p_b,p_b[2])
    end
    --self.p_b={0,0,0,0,5,6,5,6}                --t时期k种货物的单位利润
    
    self.p_b0={5,6}
    
    for i=1,self.k*self.t do
        table.insert(self.q,q[i])
    end
    
    for i=1,self.k*self.t do
        table.insert(self.q,q[i])
    end
    for i=1,self.k*self.t do
        --print(self.q[i]," self.t is ",self.t)
    end   

    return self
end

function Model:set_constrains()

    ----总投资约束----
    local x1={}
    for i=1,self.k*self.t do
        x1[i]=self.c[i]
    end
    AddConstraint(lp,x1,"<=",self.I)
    
    --------融资约束--------
    local x2={}
    for i=1,self.k*self.t do
        local temp1=i%self.k    --判断是第几种货物
        local temp2=math.modf(i/self.k)    --判断在哪个时期
        --local temp2=i/self.k
        if temp1~=0 then
            --x2[i]=(1+(self.t-temp2-1)*self.r[temp2+1])* self.y[temp2+1]*self.c[i]
            x2[i]=(1+(1+(self.t-temp2-1)*self.r[temp2+1])*self.y[temp2+1])*self.c[i]
        else
            --x2[i]=(1+(self.t-temp2)*self.r[temp2])* self.y[temp2]*self.c[i]
            x2[i]=(1+(1+(self.t-temp2)*self.r[temp2])*self.y[temp2])*self.c[i]
        end
    end
    for i=self.t*self.k+1,self.t*self.k*2 do
        x2[i]=-self.p_b[i]
    end
    AddConstraint(lp,x2,"<=",0)
    
    --------运行效率约束--------
    for i=1,self.t do
        local x3={}
        local y1=self.k*self.a
        for j=1,self.k*i do
            local temp1=j%self.k    --判断是第几种货物
            if temp1~=0 then
                x3[j]=self.Q[temp1]/self.q[j]
            else
                temp1=self.k
                x3[j]=self.Q[temp1]/self.q[j]
            end
        end
        for ix=1,self.k do
            y1=y1-self.Q[ix]/self.q[ix]*self.b_0[ix]
        end
        AddConstraint(lp,x3,"<=",y1)
    end 
    
    --------空间资源约束--------
    x4={}
    for i=1,self.k*self.t do
        x4[i]=self.l_k[i]
    end
    AddConstraint(lp,x4,"<=",self.R_space)
    
    --------空气资源约束--------
    x5={}
    for i=1,self.k*self.t*2+4 do
        x5[i]=0
    end
    x5[self.k*self.t*2+1]=self.p[1]
    AddConstraint(lp,x5,"<=",self.f[1])
    
    --------水资源约束--------
    x6={}
    for i=1,self.k*self.t*2+4 do
        x6[i]=0
    end
    x6[self.k*self.t*2+2]=self.p[2]
    AddConstraint(lp,x6,"<=",self.f[2])
    
    --------固体废弃物约束--------
    x7={}
    for i=1,self.k*self.t*2+4 do
        x7[i]=0
    end
    x7[self.k*self.t*2+3]=self.p[3]
    AddConstraint(lp,x7,"<=",self.f[3])
    
    --------噪声污染约束--------
    x8={}
    for i=1,self.k*self.t*2+4 do
        x8[i]=0
    end
    x8[self.k*self.t*2+4]=self.p[4]
    AddConstraint(lp,x8,"<=",self.f[4])
end
function Model:set_intermediate_variable()

    ---------另中间变量1小于需求量-----------
    for i=self.k*self.t+1,self.k*self.t*2 do
        local x1={}
        for j=self.k*self.t+1,self.k*self.t*2 do
            if i==j then
                x1[j]=1
            else
                x1[j]=0
            end
            --AddConstraint(lp,x1,"<=",self.q[i])
        end
       AddConstraint(lp,x1,"<=",self.q[i])
        --print(self.q[i])
    end
    
    ---------另中间变量1小于泊位建造能力---------
    for i=self.k*self.t+1,self.k*self.t*2 do
        local x2={}
        local temp1,temp2
        for j=self.k*self.t+1,self.k*self.t*2 do
            if i==j then
                x2[j]=1
                temp1=i%self.k     --判断是第几种货物
                temp2=math.modf((i-self.k*self.t)/self.k) --判断是哪个时期
                if temp1~=0 then         --非第k种货物
                    for ix=temp1,temp1+self.k*temp2,self.k do
                        x2[ix]=-self.Q[ix]
                    end
                else    --第k种货物
                    temp1=self.k
                    for iy=temp1,temp1+self.k*(temp2-1),self.k do
                        x2[iy]=-self.Q[iy]
                    end
                end
            end
        end
        for iz=1,self.t*self.k*2 do
            if x2[iz]==nil then
                x2[iz]=0
            end
        end
        AddConstraint(lp,x2,"<=",self.Q[temp1]*self.b_0[temp1])
    end
    
    --------空气资源中间变量约束------------
    local x3={}
    for i=1,self.k*self.t*2+4 do
        x3[i]=0
    end
    x3[self.k*self.t*2+1]=1
    for j=self.k*self.t+1,self.k*self.t*2 do
        x3[j]=-self.n_air[j]
    end
    AddConstraint(lp,x3,">=",-self.R[1])
    --------水资源中间变量约束------------
    local x4={}
    for i=1,self.k*self.t*2+4 do
        x4[i]=0
    end
    x4[self.k*self.t*2+2]=1
    for j=self.k*self.t+1,self.k*self.t*2 do
        x4[j]=-self.n_water[j]
    end
    AddConstraint(lp,x4,">=",-self.R[2])
    --------固体废弃物资源中间变量约束------------
    local x5={}
    for i=1,self.k*self.t*2+4 do
        x5[i]=0
    end
    x5[self.k*self.t*2+3]=1
    for j=self.k*self.t+1,self.k*self.t*2 do
        x5[j]=-self.n_solid[j]
    end
    AddConstraint(lp,x5,">=",-self.R[3])
    --------噪声资源中间变量约束------------
    local x6={}
    for i=1,self.k*self.t*2+4 do
        x6[i]=0
    end
    x6[self.k*self.t*2+4]=1
    for j=self.k*self.t+1,self.k*self.t*2 do
        x6[j]=-self.n_voice[j]
    end
    AddConstraint(lp,x6,">=",-self.R[4])
end


--[[
k=2
t=2
q={1.50690,5.70700,2,6,1.50690,5.70700,2,6}
c={5,5,5,5}
p_b={0,0,0,0,5,6,5,6}
p={0,0,0,0,0,0,0,0,20,35,20,10}

lp=CreateLP()

x={}
for i=1,t*k do
    x[i]=-c[i]
end

for i=k*t+1,k*t*2 do
    x[i]=p_b[i]
end

for i=k*t*2+1,k*t*2+4 do
    x[i]=-p[i]
end
a=Model:new(k,t,q)
b=a:set_constrains()
c=a:set_intermediate_variable()

SetObjFunction(lp,x,"max")

for i=1,k*t+4+k*t do
        SetInteger(lp,i)
end
SolveLP(lp)
WriteLP (lp,'lp1.lp')
print('best is  ',GetObjective(lp))
a = {GetVariables(lp)}
print(table.concat(a,','))
--]]