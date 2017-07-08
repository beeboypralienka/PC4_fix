tic

%--------------------------------------
% Tear-down semua display dan variable
%--------------------------------------
clc; clear;

%--------------
% Load file GR 
%--------------
PC4_01_GR = csvread('03_SeleksiFitur\PC4_GR\PC4_GR.csv');

%----------
% Seed = 1
%----------
seed = 1;
rng(seed); %Seed nilai random, jadi ga usah run berkali-kali

%-------------
% K-Fold = 5
%-------------
k = 5;
vektorPC4 = PC4_01_GR(:,1);
cvFolds = crossvalind('Kfold', vektorPC4, k);
clear vektorPC4; 
    
disp('PC4_GR Calculation in progress...');

for iFitur = 37 : -1 : 1 %Decrement
%---
    for iFold = 1 : k
    %---            
        disp([iFitur,iFold]); % Sengaja ditambahain untuk liat progres RUN
        %-------------------------------------
        % Penetapan data TRAINING dan TESTING
        %-------------------------------------
        testIdx = (cvFolds == iFold);                
        PC4_00_TrainIdx(:,iFold) = ~testIdx; %1 = training, 0 = testing        
        
        %------------------------------------------------------------------
        % Pembagian data TRANING dan TESTING berdasarkan "PC4_00_TrainIdx"        
        %------------------------------------------------------------------
        iTraining = 1; %Counter iterasi TRAINING
        iTesting = 1; %Counter iterasi TESTING                     
        for iBarisData = 1 : size(PC4_01_GR,1)  %Iterasi baris data 
            %---- TRAINING
            if PC4_00_TrainIdx(iBarisData,iFold) == 1 %Kalau TrainIdx 1                 
                PC4_02_Train{1,iFitur}{iFold,1}(iTraining,1:iFitur) = PC4_01_GR(iBarisData,1:iFitur); %Sengaja dipisah kelasnya, karena ada iterasi fitur
                PC4_02_Train{1,iFitur}{iFold,1}(iTraining,iFitur+1) = PC4_01_GR(iBarisData,end); %Tambah kelas dari kolom paling terakhir di "PC4_01_GR"
                PC4_02_Train{1,iFitur}{iFold,1}(iTraining,iFitur+2) = iBarisData; %Tambah urutan data
                iTraining = iTraining + 1; %Counter TRAINING            
            %---- TESTING
            else %kalau TrainIdx 0
                PC4_03_Test{1,iFitur}{iFold,1}(iTesting,1:iFitur) = PC4_01_GR(iBarisData,1:iFitur); %Sengaja dipisah kelasnya, karena ada iterasi fitur           
                PC4_03_Test{1,iFitur}{iFold,1}(iTesting,iFitur+1) = PC4_01_GR(iBarisData,end); %Tambah kelas dari kolom paling terakhir di "PC4_01_GR"
                PC4_03_Test{1,iFitur}{iFold,1}(iTesting,iFitur+2) = iBarisData; %Tambah urutan data
                iTesting = iTesting + 1; %Counter TESTING
            end                        
        end        
        clear iBarisData iTesting iTraining;
        
        %------------------------------------------------------
        % Pembagian data TRAINING yang kelasnya FALSE dan TRUE
        %------------------------------------------------------
        fgFalse = 0; %Flag jumlah TRAINING yang FALSE
        fgTrue = 0; %Flag jumlah TRAINING yang TRUE        
        for iJumlahTrain = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1) %Iterasi panjang TRAINING  
            %---- FALSE
            if PC4_02_Train{1,iFitur}{iFold,1}(iJumlahTrain,iFitur+1) == 0 %TRAINING kelas FALSE              
                fgFalse = fgFalse + 1; %Counter TRAINING yang FALSE
                PC4_04_Train_False{1,iFitur}{iFold,1}(fgFalse,:) = PC4_02_Train{1,iFitur}{iFold,1}(iJumlahTrain,:); %Ambil data FALSE dari urutan TRAINING            
            %---- TRUE
            else %TRAINING kelas TRUE
                fgTrue = fgTrue + 1; %Counter TRAINING yang TRUE
                PC4_05_Train_True{1,iFitur}{iFold,1}(fgTrue,:) = PC4_02_Train{1,iFitur}{iFold,1}(iJumlahTrain,:); %Ambil data TRUE dari urutan TRAINING  
            end                        
        end
        %---------------------------------------------------------
        % Update keterangan TRAINING :
        %---------------------------------------------------------
        % [1] Jumlah TRAINING
        % [2] Jumlah TRAINING yang FALSE
        % [3] Jumlah TRAINING yang TRUE
        % [4] Jumlah duplikasi TRAINING dengan kelas yang berbeda
        %---------------------------------------------------------
        jumlahUnique = size( unique( PC4_02_Train{1,end}{iFold,1}(:,1:end-2),'rows' ) ,1); %end-2 itu karena selain semua fitur, ada plus kelas dan plus urutannya
        duplikasi = iJumlahTrain - jumlahUnique; %Hitung duplikasi di data TRAINING
        PC4_02_Train_Keterangan{iFold,1} = [iJumlahTrain fgFalse fgTrue duplikasi]; %Keterangan TRAINING
        clear fgFalse fgTrue iJumlahTrain jumlahUnique duplikasi; 
        
        %---------------------------------------------------------
        % Update keterangan TESTING :
        %---------------------------------------------------------
        % [1] Jumlah TESTING
        % [2] Jumlah TESTING yang FALSE
        % [3] Jumlah TESTING yang TRUE
        % [4] Jumlah duplikasi TESTING dengan kelas yang berbeda
        %---------------------------------------------------------
        fgFalse = 0;
        fgTrue = 0;
        for iJumlahTesting = 1 : size(PC4_03_Test{1,end}{iFold,1},1)
            if PC4_03_Test{1,end}{iFold,1}(iJumlahTesting,end-1) == 0
                fgFalse = fgFalse + 1;
            else
                fgTrue = fgTrue + 1;
            end
        end
        jumlahUnique = size( unique( PC4_03_Test{1,end}{iFold,1}(:,1:end-2),'rows' ) ,1); %end-2 itu karena selain semua fitur, ada plus KELAS dan plus URUTAN
        duplikasi = iJumlahTesting - jumlahUnique; %Hitung duplikasi di data TESTING
        PC4_03_Test_Keterangan{iFold,1} = [iJumlahTesting fgFalse fgTrue duplikasi]; %Keterangan TESTING
        clear fgFalse fgTrue iJumlahTesting jumlahUnique duplikasi; 
                                 
        %--------------------------------------------------------------------------------------
        % Cek pemilihan titik C1 jangan sampai pilih yang duplikat dengan kelas berbeda (TRUE)
        %--------------------------------------------------------------------------------------
        kFalse{1,iFitur}{iFold,1} = randperm(size(PC4_04_Train_False{1,iFitur}{iFold,1},1)); %Acak urutan data "TRAINING FALSE"
        TrainTrue{iFold,1} = PC4_05_Train_True{1,end}{iFold,1}; %Duplikat matrik TRAINING yang kelasnya TRUE untuk cek duplikasi C1, langsung ambil semua fitur 1 hingga end
        urutanKFalse = 1; %Ambil urutan dari nilai random kFalse
        duplikatC1 = true; %Kondisi while loop
        while duplikatC1                        
            TrainTrue{iFold,1}(end+1,:) = PC4_04_Train_False{1,end}{iFold,1}( kFalse{1,end}{iFold,1}(1,urutanKFalse) ,:); %Di akhir data TRAINING TRUE ditambah satu data TRAINING FALSE, langsung semua fitur 1 hingga end
            %----------------------------------------------
            % Kalau jumlah GAK sama, berarti NO duplikasi
            %----------------------------------------------
            if size(PC4_05_Train_True{1,end}{iFold,1},1) ~= size(unique(TrainTrue{iFold,1}(:,end),'rows'),1) %Kalau dibikin uniqe (semua fitur, 1 hingga end) jumlahnya ga sama, berarti gada duplikasi
                duplikatC1 = false; %Looping while berhenti
                PC4_06_Titik_C1{1,iFitur}{iFold,1} = PC4_04_Train_False{1,iFitur}{iFold,1}( kFalse{1,end}{iFold,1}(1,urutanKFalse) ,:); %Titik C1 diambil dari TRAINING FALSE yang bukan duplikasi, dari kFalse fitur lengkap (terakhir)
            %---------------
            % ADA duplikasi
            %---------------
            else %Ketika dibikin uniqe, jumlahnya jadi sama, maka ada duplikasi data dengan kelas yang berbeda                
                TrainTrue{iFold,1}(end,:) = []; %Satu data di baris paling akhir (end) di-delete, karena bukan data asli TRAINING TRUE
                urutanKFalse = urutanKFalse + 1; %Nanti ambil urutan kFalse selanjutnya
            end            
        end 
        clear urutanKFalse duplikatC1 TrainTrue;
        
        %--------------------------------------------------------------------------------------
        % Cek pemilihan titik C2 jangan sampai pilih yang duplikat dengan kelas berbeda (FALSE)
        %--------------------------------------------------------------------------------------
        kTrue{1,iFitur}{iFold,1} = randperm(size(PC4_05_Train_True{1,iFitur}{iFold,1},1)); %Acak urutan data "TRAINING TRUE"         
        TrainFalse{iFold,1} = PC4_04_Train_False{1,end}{iFold,1}; %Duplikat matrik TRAINING yang kelasnya FALSE untuk cek duplikasi C2, langsung ambil semua fitur 1 hingga end
        urutanKTRUE = 1; %Ambil urutan dari nilai random kTRUE
        duplikatC2 = true; %Kondisi while loop
        while duplikatC2                        
            TrainFalse{iFold,1}(end+1,:) = PC4_05_Train_True{1,end}{iFold,1}( kTrue{1,end}{iFold,1}(1,urutanKTRUE) ,:); %Di akhir data TRAINING FALSE ditambah satu data TRAINING TRUE, langsung semua fitur 1 hingga end
            %----------------------------------------------
            % Kalau jumlah GAK sama, berarti NO duplikasi
            %----------------------------------------------
            if size(PC4_04_Train_False{1,end}{iFold,1},1) ~= size(unique(TrainFalse{iFold,1}(:,1:end),'rows'),1) %Kalau dibikin uniqe (semua fitur, 1 hingga end) jumlahnya ga sama, berarti gada duplikasi
                duplikatC2 = false; %Looping while berhenti
                PC4_07_Titik_C2{1,iFitur}{iFold,1} = PC4_05_Train_True{1,iFitur}{iFold,1}( kTrue{1,end}{iFold,1}(1,urutanKTRUE) ,:); %Titik C2 diambil dari TRAINING TRUE yang bukan duplikasi, dari kTrue fitur lengkap (terakhir)
            %---------------
            % ADA duplikasi
            %---------------
            else %Ketika dibikin uniqe, jumlahnya jadi sama, maka ada duplikasi data dengan kelas yang berbeda                
                TrainFalse{iFold,1}(end,:) = []; %Satu data di baris paling akhir (end) di-delete, karena bukan data asli TRAINING FALSE
                urutanKTRUE = urutanKTRUE + 1; %Nanti ambil urutan kTrue selanjutnya
            end            
        end 
        clear urutanKTRUE duplikatC2 TrainFalse;            
        
%==============================================================================================
%                                    ==  FASE 1  ===
%==============================================================================================
        
        %----------------------------------------------------------------
        % Hitung hamming distance masing-masing fitur terhadap C1 dan C2
        %----------------------------------------------------------------
        for iKolomCluster = 1 : iFitur
            for iBarisCluster = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1) %Iterasi baris data per fold di setiap iterasi fitur             
                %------------------------------------
                % Hitung jarak data ke titik cluster
                %------------------------------------
                data = PC4_02_Train{1,iFitur}{iFold,1}(iBarisCluster,iKolomCluster); %Data fitur yang ke iKolomCluster

                %------------------------
                % Jarak tiap fitur ke C1
                %------------------------
                C1 = PC4_06_Titik_C1{1,iFitur}{iFold,1}(1,iKolomCluster); %Data titik C1 yang ke iKolomCluster                                
                jarakHamming = hammingDistance_fix(data,C1); %Panggil fungsi perhitungan jarak hamming dari data ke titik C1
                PC4_08_HamDist_C1{1,iFitur}{iFold,1}(iBarisCluster,iKolomCluster) = jarakHamming; %Simpan perhitungan jarak hamming C1

                %------------------------
                % Jarak tiap fitur ke C2
                %------------------------
                C2 = PC4_07_Titik_C2{1,iFitur}{iFold,1}(1,iKolomCluster); %Data titik C2 yang ke iKolomCluster                                                               
                jarakHamming = hammingDistance_fix(data,C2); %Panggil fungsi perhitungan jarak hamming dari data ke titik C2
                PC4_09_HamDist_C2{1,iFitur}{iFold,1}(iBarisCluster,iKolomCluster) = jarakHamming; %Simpan perhitungan jarak hamming C2                                           
            end 
        end
        clear iBarisCluster jarakHamming data C1 C2 iKolomCluster;
        
        %-----------------------------------------------------------------------
        % Menghitung rata-rata setiap baris hamming distance pada seleksi fitur
        %-----------------------------------------------------------------------        
        PC4_10_Avg_HamDist{1,iFitur}{iFold,1}(:,1) = mean(PC4_08_HamDist_C1{1,iFitur}{iFold,1},2); % Rata-rata per baris ke C1
        PC4_10_Avg_HamDist{1,iFitur}{iFold,1}(:,2) = mean(PC4_09_HamDist_C2{1,iFitur}{iFold,1},2); % Rata-rata per baris ke C2
        
        %--------------------------------------------------------------------------------------------------------------
        % Penentuan anggota C1 atau C2 berdasarkan jarak rata-rata terdekat --> Update kolom ke 3 "PC4_10_Avg_HamDist"
        %--------------------------------------------------------------------------------------------------------------
        for iBarisAvg = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1)
            averageC1 = PC4_10_Avg_HamDist{1,iFitur}{iFold,1}(iBarisAvg,1); %Jarak rata-rata baris hamming distance C1
            averageC2 = PC4_10_Avg_HamDist{1,iFitur}{iFold,1}(iBarisAvg,2); %Jarak rata-rata baris hamming distance C2                                    
            if averageC1 > averageC2                
                PC4_10_Avg_HamDist{1,iFitur}{iFold,1}(iBarisAvg,3) = 22222; %Anggota C2
            else PC4_10_Avg_HamDist{1,iFitur}{iFold,1}(iBarisAvg,3) = 11111; %Anggota C1
            end                                                              
        end
        clear iBarisAvg averageC1 averageC2;
           
        %----------------------------------------------------------
        % Pengelompokan data C1 dan C2 berdasarkan 11111 dan 22222
        %----------------------------------------------------------
        fgC1 = 0; %Flag counter urutan anggota C1
        fgC2 = 0; %Flag counter urutan anggota C2
        for iBarisKelompok = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1)  
            if PC4_10_Avg_HamDist{1,iFitur}{iFold,1}(iBarisKelompok,3) == 11111 %Kalau data lebih dekat ke C1, maka jadi anggota C1     
                fgC1 = fgC1 + 1; %Counter flag C1 untuk urutan anggota C1
                PC4_11_Anggota_C1{1,iFitur}{iFold,1}(fgC1,:) = PC4_02_Train{1,iFitur}{iFold,1}(iBarisKelompok,1:iFitur+2); %Ambil semua baris data TRAINING, termasuk kelas dan urutannya                
            else %Kalau data lebih dekat ke C2, maka jadi anggota C2     
                fgC2 = fgC2 + 1; %Counter flag C2 untuk urutan anggota C2
                PC4_12_Anggota_C2{1,iFitur}{iFold,1}(fgC2,:) = PC4_02_Train{1,iFitur}{iFold,1}(iBarisKelompok,1:iFitur+2); %Ambil semua baris data TRAINING, termasuk kelas dan urutannya
            end                        
        end
        %-------------------------------------------------------------------------------------------------------------
        % Prevent Fold "PC4_12_Anggota_C2" yang hilang karena tidak dianggap ada oleh matLab, dibuat matrix kosong []  
        %-------------------------------------------------------------------------------------------------------------
        if size(PC4_11_Anggota_C1{1,iFitur}{iFold,1},1) == size(PC4_02_Train{1,iFitur}{iFold,1},1) %Jumlah anggota C1 == jumlah data TRAINING, maka anggota C2 = []
            PC4_12_Anggota_C2{1,iFitur}{iFold,1} = []; %Anggota C2 dibuat matrik kosong
        end        
        clear fgC1 fgC2 iBarisKelompok;    
        
        %----------------------------------
        % Hitung MEAN per fitur anggota C1
        %----------------------------------
        PC4_13_Mean_C1{1,iFitur}{iFold,1}(1,:) = mean(PC4_11_Anggota_C1{1,iFitur}{iFold,1}(:,1:iFitur)); %Hitung mean per kolom anggota C1               
        
        %----------------------------------
        % Hitung MEAN per fitur anggota C2
        %----------------------------------
        if size(PC4_12_Anggota_C2{1,iFitur},1) ~= 0 %Cek apakah FOLD ada datanya? Kalau ada, lanjut...
            if size(PC4_12_Anggota_C2{1,iFitur}{iFold,1},1) ~= 0 %Cek apakah data per FOLD ada? Kalau ada, lanjut...                  
                %---------------------------------------------------------
                % Kondisi kalau baris datanya cuma 1, ga usah hitung mean
                %---------------------------------------------------------
                if size(PC4_12_Anggota_C2{1,iFitur}{iFold,1},1) == 1
                    PC4_14_Mean_C2{1,iFitur}{iFold,1}(1,:) = PC4_12_Anggota_C2{1,iFitur}{iFold,1}; %Ga usah hitung mean, karena cuma satu data
                else
                    PC4_14_Mean_C2{1,iFitur}{iFold,1}(1,:) = mean(PC4_12_Anggota_C2{1,iFitur}{iFold,1}(:,1:iFitur)); %Hitung mean per kolom anggota C2
                end                  
            end            
        end         
        %----------------------------------------------------------------------------------------------------------
        % Prevent Fold "PC4_14_Mean_C2" yang hilang karena tidak dianggap ada oleh matLab, dibuat matrix kosong []  
        %----------------------------------------------------------------------------------------------------------
        if size(PC4_11_Anggota_C1{1,iFitur}{iFold,1},1) == size(PC4_02_Train{1,iFitur}{iFold,1},1) %Jumlah anggota C1 == jumlah data TRAINING, maka MEAN C2 = []
            PC4_14_Mean_C2{1,iFitur}{iFold,1} = []; %Mean C2 dibuat matrik kosong
        end
        
        %-------------------------------------------------
        % Pembulatan nilai MEAN --> C1 "new" dan C2 "new"
        %-------------------------------------------------        
        for iSeleksiFitur = 1 : iFitur                        
            %---------
            % MEAN C1
            %---------
            nilaiMeanC1 = PC4_13_Mean_C1{1,iFitur}{iFold,1}(1,iSeleksiFitur); %Nilai mean C1 per TOP iFitur
            pembulatanC1 = pembulatanMEAN_fix(nilaiMeanC1); %Pembualatan data C1 per fitur
            PC4_15_Titik_C1_New{1,iFitur}{iFold,1}(1,iSeleksiFitur) = pembulatanC1; %Simpan setiap pembulatan data C1 per fitur --> Jadi C1 New            
            %---------
            % MEAN C2
            %---------
            if size(PC4_14_Mean_C2{1,iFitur},1) ~= 0 %Cek fitur 'PC4_14_Mean_C2' metrik kosong bukan, kalau bukan, lanjut..
                if size(PC4_14_Mean_C2{1,iFitur}{iFold,1},1) ~= 0 %Cek fold 'PC4_14_Mean_C2' metrik kosong bukan, kalau bukan, lanjut..
                    nilaiMeanC2 = PC4_14_Mean_C2{1,iFitur}{iFold,1}(1,iSeleksiFitur); %Nilai mean C2 per TOP iFitur
                    pembulatanC2 = pembulatanMEAN_fix(nilaiMeanC2); %Pembualatan data C2 per fitur
                    PC4_16_Titik_C2_New{1,iFitur}{iFold,1}(1,iSeleksiFitur) = pembulatanC2; %Simpan setiap pembulatan data C2 per fitur --> Jadi C2 New
                end
            end             
            %------------------------------------------------------------------------------------------------
            % Prevent Fold < 10 untuk anggota C2, jadi metrik kosong di akhir dianggap tidak ada sama matLab    
            %------------------------------------------------------------------------------------------------
            if size(PC4_11_Anggota_C1{1,iFitur}{iFold,1},1) == size(PC4_02_Train{1,iFitur}{iFold,1},1) %Jumlah anggota C1 == jumlah data TRAINING, maka C2 New = []
                PC4_16_Titik_C2_New{1,iFitur}{iFold,1} = []; %Titik C2 new dibuat matrik kosong, karena memang gada anggotanya
            end            
        end
        clear iSeleksiFitur nilaiMeanC1 nilaiMeanC2 pembulatanC1 pembulatanC2                        
        
%==============================================================================================
%                                    ==  FASE 2  ===
%==============================================================================================        
            
        %----------------------------------------------------------------------------
        % Hitung hamming distance masing-masing fitur terhadap "C1_new" dan "C2_new"
        %----------------------------------------------------------------------------
        for iKolomCluster = 1 : iFitur
            for iBarisCluster = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1)              
                %-------------------------------------------
                % Hitung jarak data ke titik cluster "new"
                %-------------------------------------------
                data = PC4_02_Train{1,iFitur}{iFold,1}(iBarisCluster,iKolomCluster);

                %------------------------------
                % Jarak tiap fitur ke "C1_new"
                %------------------------------
                C1 = PC4_15_Titik_C1_New{1,iFitur}{iFold,1}(1,iKolomCluster);                                
                jarakHamming = hammingDistance_fix(data,C1);
                PC4_17_HamDist_C1_new{1,iFitur}{iFold,1}(iBarisCluster,iKolomCluster) = jarakHamming;

                %------------------------------
                % Jarak tiap fitur ke "C2_new"
                %------------------------------                
                if size(PC4_16_Titik_C2_New{1,iFitur}{iFold,1},1) ~= 0                                        
                    C2 = PC4_16_Titik_C2_New{1,iFitur}{iFold,1}(1,iKolomCluster);                  
                    jarakHamming = hammingDistance_fix(data,C2);
                    PC4_18_HamDist_C2_new{1,iFitur}{iFold,1}(iBarisCluster,iKolomCluster) = jarakHamming;                    
                else
                    PC4_18_HamDist_C2_new{1,iFitur}{iFold,1} = [];
                end                
            end
        end
        clear iBarisCluster jarakHamming data C1 C2 iKolomCluster;                        
        
        %-----------------------------------------------------------------------
        % Menghitung rata-rata setiap baris hamming distance pada seleksi fitur
        %-----------------------------------------------------------------------        
        PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(:,1) = mean(PC4_17_HamDist_C1_new{1,iFitur}{iFold,1},2); % Rata-rata per baris
        %---------------------------------------------------------
        % Selama tidak ada metrik kosong pada hamming distance C2
        %---------------------------------------------------------
        if size(PC4_18_HamDist_C2_new{1,iFitur}{iFold,1},1) ~= 0 
            PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(:,2) = mean(PC4_18_HamDist_C2_new{1,iFitur}{iFold,1},2); % Rata-rata per baris
        %--------------------------------------------------
        % Kalau ADA metrik kosong pada hamming distance C2
        %--------------------------------------------------
        else
            for iKosong = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1)
                PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(iKosong,2) = 9999; % Sengaja dibuat jauh jaraknya
            end            
        end 
        clear iKosong;
        
        %-------------------------------------------------------------------------------
        % Penentuan anggota "C1_new" atau "C2_new" berdasarkan jarak rata-rata terdekat
        %-------------------------------------------------------------------------------
        for iBarisAvg = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1)        
            averageC1 = PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(iBarisAvg,1);            
            averageC2 = PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(iBarisAvg,2);                                 
            if averageC1 > averageC2                                
                PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(iBarisAvg,3) = 22222;
            else PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(iBarisAvg,3) = 11111;
            end                                                                                                                                                                  
        end
        clear iBarisAvg averageC1 averageC2;           
        
        %----------------------------------------------------------------------
        % Pengelompokan data "C1_new" dan "C2_new" berdasarkan 11111 dan 22222
        %----------------------------------------------------------------------
        fgC1 = 0;
        fgC2 = 0;
        for iBarisKelompok = 1 : size(PC4_02_Train{1,iFitur}{iFold,1},1)  
            if PC4_19_Avg_HamDist_new{1,iFitur}{iFold,1}(iBarisKelompok,3) == 11111     
                fgC1 = fgC1 + 1;
                PC4_20_Anggota_C1_new{1,iFitur}{iFold,1}(fgC1,:) = PC4_02_Train{1,iFitur}{iFold,1}(iBarisKelompok,1:iFitur+2);                
            else
                fgC2 = fgC2 + 1;
                PC4_21_Anggota_C2_new{1,iFitur}{iFold,1}(fgC2,:) = PC4_02_Train{1,iFitur}{iFold,1}(iBarisKelompok,1:iFitur+2);
            end                        
        end
        %-----------------------------------------------------------------------------------------------------------------
        % Prevent Fold "PC4_21_Anggota_C2_new" yang hilang karena tidak dianggap ada oleh matLab, dibuat matrix kosong []  
        %-----------------------------------------------------------------------------------------------------------------
        if size(PC4_20_Anggota_C1_new{1,iFitur}{iFold,1},1) == size(PC4_02_Train{1,iFitur}{iFold,1},1)
            PC4_21_Anggota_C2_new{1,iFitur}{iFold,1} = [];
        end        
        clear fgC1 fgC2 iBarisKelompok;  
        
%==============================================================================================
%                                    ==  WHILE  ===
%==============================================================================================                        
        
        %------------------------------------------------------------------------------------------
        % 1. Cek apakah anggota C1 dan C2 yang lama sudah sama dengan yang baru? If ya = konvergen
        % 2. If tidak = Hitung lagi, cari anggota C1 dan C2 yang baru
        %------------------------------------------------------------------------------------------
        PC4_22_____________________ = 0;
        PC4_23_Anggota_C1_Awal{1,iFitur}{iFold,1} = PC4_11_Anggota_C1{1,iFitur}{iFold,1};
        PC4_24_Anggota_C2_Awal{1,iFitur}{iFold,1} = PC4_12_Anggota_C2{1,iFitur}{iFold,1};         
        PC4_25_____________________ = 0;        
        PC4_26_Anggota_C1_Temp{1,iFitur}{iFold,1} = PC4_20_Anggota_C1_new{1,iFitur}{iFold,1};               
        %------------------------------------------------------------------------------------------------------------------
        % Prevent Fold "PC4_27_Anggota_C2_Temp" yang hilang karena tidak dianggap ada oleh matLab, dibuat matrix kosong []
        %------------------------------------------------------------------------------------------------------------------
        if size(PC4_24_Anggota_C2_Awal{1,iFitur}{iFold,1},1) ~=0            
            PC4_27_Anggota_C2_Temp{1,iFitur}{iFold,1} = PC4_24_Anggota_C2_Awal{1,iFitur}{iFold,1};
        else PC4_27_Anggota_C2_Temp{1,iFitur}{iFold,1} = [];
        end                                                               
        PC4_28_____________________ = 0;       
        
        %-------------------------------------------
        % Untuk menghitung iterasi hingga konvergen
        %-------------------------------------------
        PC4_44_JumlahIterasi{1,iFitur}{iFold,1} = 0;

        %--------------------------------------------------------------------------
        % Cek dulu apakah LENGTH anggota C1 (awal) == LENGTH anggota C1_new (temp)
        %--------------------------------------------------------------------------
        if size(PC4_23_Anggota_C1_Awal{1,iFitur}{iFold,1},1) == size(PC4_26_Anggota_C1_Temp{1,iFitur}{iFold,1},1)
            %------------------------------------------------------------------------------------------------
            % Cek apakah susunan masing-masing anggota sudah sama? Kalau YA, langsung ambil titik C1 dan C2
            %------------------------------------------------------------------------------------------------
            if PC4_23_Anggota_C1_Awal{1,iFitur}{iFold,1} == PC4_26_Anggota_C1_Temp{1,iFitur}{iFold,1}
                %Joss{1,iFitur}{iFold,1} = 11111;
                PC4_31_Titik_C1_Temp{1,iFitur}{iFold,1} = PC4_15_Titik_C1_New{1,iFitur}{iFold,1};
                PC4_32_Titik_C2_Temp{1,iFitur}{iFold,1} = PC4_16_Titik_C2_New{1,iFitur}{iFold,1};
            %--------------------------------------------------------------------
            % Kalau susunan beda, lakukan iterasi hingga kedua anggota konvergen
            %--------------------------------------------------------------------
            else
                %Joss{1,iFitur}{iFold,1} = [];
                PC4_44_JumlahIterasi{1,iFitur}{iFold,1} = PC4_44_JumlahIterasi{1,iFitur}{iFold,1} + 1; %counter iterasi
                %----------------------------------------------------------------------
                % Cari anggota baru hingga konvergen --> Panggil method WHILE konvergen
                %----------------------------------------------------------------------
                konvergensi_fix; %Panggil method WHILE konvergen                
            end
        %---------------------------------------------------------------
        % Kalau LENGTH anggota C1 (awal) != LENGTH anggota C1_new (temp)
        %---------------------------------------------------------------
        else
            %Joss{1,iFitur}{iFold,1} = [];
            PC4_44_JumlahIterasi{1,iFitur}{iFold,1} = PC4_44_JumlahIterasi{1,iFitur}{iFold,1} + 1; %counter iterasi
            %----------------------------------------------------------------------
            % Cari anggota baru hingga konvergen --> Panggil method WHILE konvergen
            %----------------------------------------------------------------------
            konvergensi_fix; %Panggil method WHILE konvergen            
        end
          
%==============================================================================================
%                                   ==  TESTING  ===
%==============================================================================================    
        
        %-----------------------------------------------------------
        % Pengujian per FOLD (ada 5) di setiap iterasi TOP X FITUR 
        %----------------------------------------------------------- 
        testing_fix; %(TP, FN, TN, FP) ==> (PD, PF, BAL)
                
    %---    
    end
%---
end

toc

%----------------------
% PC4_55_MAX_Mean_PD:
%----------------------
% [1] Urutan
% [2] Nilai MAX
%----------------------
[nilai,urutan] = max(PC4_50_Mean_PD); %Cari nilai maximum PD dan urutannya
PC4_55_MAX_Mean_PD = [urutan nilai]; %Simpan ke 'PC4_55_MAX_Mean_PD'
clear nilai urutan;

%----------------------
% PC4_56_MIN_Mean_PF:
%----------------------
% [1] Urutan
% [2] Nilai MIN
%----------------------
[nilai,urutan] = min(PC4_52_Mean_PF); %Cari nilai minimum PF dan urutannya
PC4_56_MIN_Mean_PF = [urutan nilai]; %Simpan ke 'PC4_56_MIN_Mean_PF'
clear nilai urutan;

%----------------------
% PC4_57_MAX_Mean_BAL:
%----------------------
% [1] Urutan
% [2] Nilai MAX
% [3] Jumlah fitur
% [4] Elapsed time
% [5] Seed
%----------------------
[nilai,urutan] = max(PC4_54_Mean_BAL); %Cari nilai maximum BAL dan urutannya
PC4_57_MAX_Mean_BAL = [urutan nilai size(PC4_01_GR,2)-1 toc seed]; %Simpan ke 'PC4_57_MAX_Mean_BAL'
clear nilai urutan;

clear cvFolds iFold testIdx k iFitur konvergen kFalse kTrue seed;

disp('Saving...');
    tic
        save('04_CBC\PC4_GR_CBC_FOLD_5.mat');        
    toc
disp('Done!');

load chirp %gong
sound(y,Fs)
clear y Fs;