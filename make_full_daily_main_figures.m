A = load(fullfile(pwd,'full_daily_s1','full_daily_s1.mat'),'R','P'); ES=A.R; P=A.P;
A = load(fullfile(pwd,'full_daily_s3','full_daily_s3.mat'),'R'); SA=A.R;
out=fullfile(pwd,'figures'); if ~exist(out,'dir'),mkdir(out);end
rr={ES,SA}; names={'ES: equal sharing','SA: health aware'};
colors=lines(4); group=[0.04 0.45 0.72;0.85 0.33 0.10];

f=figure('Color','w','Position',[50 50 1500 600],'Visible','off');
tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for s=1:2
    R=rr{s};nexttile;hold on;
    for i=1:4
        plot([0;R.yr],[P.SoH0(i);R.SoH(:,i)],'Color',colors(i,:),'LineWidth',1.6);
    end
    yline(P.sohEol,'k--','SoH 0.65','LineWidth',1.2);
    xline(R.eolYear,':',sprintf('%.3f y',R.eolYear),'LineWidth',1.2);
    xlabel('Second-life year');ylabel('Module SoH');title(names{s});
    ylim([0.63 0.94]);xlim([0 13]);grid on;
    if s==1,legend({'M1','M2','M3','M4'},'Location','southwest');end
end
exportgraphics(f,fullfile(out,'fig04_full_daily_soh.png'),'Resolution',300);close(f);

f=figure('Color','w','Position',[50 50 1600 550],'Visible','off');
tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
labels={'ES','SA'};
for panel=1:3
    nexttile;hold on;
    for s=1:2
        R=rr{s};x=[0;R.yr];
        if panel==1,y=[min(P.SoH0);min(R.SoH,[],2)];
        elseif panel==2,y=[1;sum(R.SoH,2)/sum(P.SoH0)];
        else,y=[max(P.SoH0)-min(P.SoH0);max(R.SoH,[],2)-min(R.SoH,[],2)];end
        plot(x,y,'Color',group(s,:),'LineWidth',1.7);
    end
    if panel==1,yline(P.sohEol,'k--','SoH 0.65');ylabel('Weakest-module SoH');
    elseif panel==2,ylabel('Bank capacity / initial');
    else,ylabel('SoH spread (max - min)');end
    xlim([0 12]);xlabel('Second-life year');grid on;
    if panel==1,legend(labels,'Location','best');end
end
exportgraphics(f,fullfile(out,'fig05_full_daily_bank.png'),'Resolution',300);close(f);

f=figure('Color','w','Position',[50 50 1600 550],'Visible','off');
tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
for panel=1:3
    nexttile;hold on;
    for s=1:2
        R=rr{s};x=(1:8)';
        if panel==1,y=mean(reshape(R.util(1:8*365),365,8),1)'*100;
        elseif panel==2,y=sum(reshape(R.Eun(1:8*365),365,8),1)';
        else,y=sum(reshape(R.Vol(1:8*365),365,8),1)'/1000;end
        plot(x,y,'-o','Color',group(s,:),'LineWidth',1.6,'MarkerSize',4);
    end
    if panel==1,ylabel('Mean daily capacity use (%)');
    elseif panel==2,ylabel('Unserved pump energy (kWh/year)');
    else,ylabel('Water pumped (10^3 m^3/year)');end
    xlim([1 8]);xticks(1:8);xlabel('Matched full-daily year');grid on;
    if panel==1,legend(labels,'Location','best');end
end
exportgraphics(f,fullfile(out,'fig06_full_daily_service.png'),'Resolution',300);close(f);
fprintf('Saved full-daily Figures 4-6\n');
