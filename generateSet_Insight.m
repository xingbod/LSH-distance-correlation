
% load('../data\lfw_512_insightface_embeddings.mat')
% load('data\lfw_256_all_embeddings_BLUFR_20170512.mat')
load('..\data\lfw\lfw_512_insightface_embeddings.mat')
load('..\data\lfw\lfw_label.mat')
backgrndamount=[0 1000 2000 5000 8000];


randnum=orth(rand(size(lfw_512_insightface_embeddings_BLUFR,2)));

for a=1:size(lfw_512_insightface_embeddings_BLUFR,1)
    new_lfw_512_insightface_embeddings_BLUFR(a,:)=lfw_512_insightface_embeddings_BLUFR(a,:)* randnum;
end

fusion_embedding=[  new_lfw_512_insightface_embeddings_BLUFR ];
Zfusion_embedding = zscore(fusion_embedding,0,2);
Descriptors = Zfusion_embedding/norm(Zfusion_embedding);

mAP_iom = zeros(length(backgrndamount),3,9); % open-set identification false accept rates of the 10 trials
M = containers.Map({'abc'},{[]});
for i=1:length(lfwlables)
    if isKey(M,char(lfwlables(i)))
        M(char(lfwlables(i))) = [M(char(lfwlables(i))); Descriptors(i,:)];
    else
        M(char(lfwlables(i)))=Descriptors(i,:);
    end
end
remove(M,'abc');

%% three group
allnames=M.keys;
known= containers.Map({'abc'},{[]});
known_unknowns= containers.Map({'abc'},{[]});
unknown_unknowns= containers.Map({'abc'},{[]});
for nameidx=1:length(allnames)
    thisuseremplate=M(allnames{nameidx});
    cnt=size(thisuseremplate,1);
    if cnt>=4
        known(allnames{nameidx})=  M(allnames{nameidx});
    elseif cnt>1
        known_unknowns(allnames{nameidx})=  M(allnames{nameidx});
    else
        unknown_unknowns(allnames{nameidx})=  M(allnames{nameidx});
    end
end
remove(known,'abc');
remove(known_unknowns,'abc');
remove(unknown_unknowns,'abc');

%% train set and  insightface_gallery probe set
insightface_train_set=[];
insightface_train_label=[];

insightface_gallery=[];
insightface_gallery_label=[];

known_names=known.keys;
for nameidx=1:length(known_names)
    thisuseremplate=known(known_names{nameidx});
    insightface_train_set = [insightface_train_set ;thisuseremplate(1:3,:) ];
    insightface_train_label=[insightface_train_label repmat(string(known_names{nameidx}),1,3)];
end

insightface_gallery = insightface_train_set;
insightface_gallery_label = insightface_train_label;

known_unknowns_names=known_unknowns.keys;
for nameidx=1:length(known_unknowns_names)
    thisuseremplate=known_unknowns(known_unknowns_names{nameidx});
    insightface_train_set = [insightface_train_set ;thisuseremplate(1,:) ];
    insightface_train_label=[insightface_train_label string(known_unknowns_names{nameidx})];
end
% remaining as insightface_probe_c
S=[];
S_label=[];
for nameidx=1:length(known_names)
    thisuseremplate=known(known_names{nameidx});
    cnt=size(thisuseremplate,1);
    S = [S ;thisuseremplate(4:end,:) ];
    S_label=[S_label repmat(string(known_names{nameidx}),1,cnt-3)];
end
% S union K  o1

K=[];
K_label=[];
for nameidx=1:length(known_unknowns_names)
   thisuseremplate=known_unknowns(known_unknowns_names{nameidx});
    cnt=size(thisuseremplate,1);
    K = [K ;thisuseremplate(2:end,:) ];
    K_label=[K_label repmat(string(known_unknowns_names{nameidx}),1,cnt-1)];
end

% S union U  o2
U=[];
U_label=[];
unknown_unknowns_names=unknown_unknowns.keys;
for nameidx=1:length(unknown_unknowns_names)
    thisuseremplate=unknown_unknowns(unknown_unknowns_names{nameidx});
    U = [U ;thisuseremplate(1,:) ];
    U_label=[U_label string(unknown_unknowns_names{nameidx})];
end

insightface_probe_c=S;
insightface_probe_label_c=S_label;

insightface_probe_o1=[S ; K];
insightface_probe_label_o1=[S_label K_label];

insightface_probe_o2=[S;U];
insightface_probe_label_o2=[S_label U_label];

insightface_probe_o3=[S;K;U];
insightface_probe_label_o3=[S_label K_label U_label];

%label trans to number
for nameidx=1:length(allnames)
   insightface_probe_label_c(find(insightface_probe_label_c==string(allnames{nameidx})))=nameidx;
   insightface_probe_label_o1(find(insightface_probe_label_o1==string(allnames{nameidx})))=nameidx;
   insightface_probe_label_o2(find(insightface_probe_label_o2==string(allnames{nameidx})))=nameidx;
   insightface_probe_label_o3(find(insightface_probe_label_o3==string(allnames{nameidx})))=nameidx;
   insightface_train_label(find(insightface_train_label==string(allnames{nameidx})))=nameidx;
   insightface_gallery_label(find(insightface_gallery_label==string(allnames{nameidx})))=nameidx;
end
% I also dont want to do so

insightface_probe_label_c = double(insightface_probe_label_c);
insightface_probe_label_o1 = double(insightface_probe_label_o1);
insightface_probe_label_o2 = double(insightface_probe_label_o2);
insightface_probe_label_o3 = double(insightface_probe_label_o3);
insightface_train_label = double(insightface_train_label);
insightface_gallery_label = double(insightface_gallery_label);

save('data/insightface_train_set.mat','insightface_train_set');
save('data/insightface_train_label.mat','insightface_train_label');
save('data/insightface_gallery.mat','insightface_gallery');
save('data/insightface_gallery_label.mat','insightface_gallery_label');
save('data/insightface_probe_c.mat','insightface_probe_c');
save('data/insightface_probe_label_c.mat','insightface_probe_label_c');
save('data/insightface_probe_o1.mat','insightface_probe_o1');
save('data/insightface_probe_o2.mat','insightface_probe_o2');
save('data/insightface_probe_o3.mat','insightface_probe_o3');
save('data/insightface_probe_label_o1.mat','insightface_probe_label_o1');
save('data/insightface_robe_label_o2.mat','insightface_probe_label_o2');
save('data/insightface_probe_label_o3.mat','insightface_probe_label_o3');


%% here all ready 
%insightface_train_set  insightface_train_label insightface_gallery insightface_gallery_label insightface_probe_c insightface_probe_o1 insightface_probe_o2  insightface_probe_o3
