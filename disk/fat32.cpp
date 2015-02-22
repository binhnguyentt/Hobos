#include <stdio.h>
#include <string.h>

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;

struct chs_address {
	uchar head;
	uchar sector:6;
	uchar cylinder_high:2;
	uchar cylinder_low;
} __attribute__((packed));

struct partition_entry {
	uchar status;
	struct chs_address start;
	uchar type;
	struct chs_address end;
	uint lba_first_sector;
	uint num_of_sectors;

} __attribute__((packed));

ushort get_cylinder(chs_address *chs) {
	ushort cylinder = chs->cylinder_low;
	cylinder = cylinder | (chs->cylinder_high << 8);
	
	return cylinder;
}

struct oem_block {
	ushort 	jump_ins;	// 0-2
	uchar 	nop_ins;	
	
	uchar 	oem_name[8];	// 3-10
	ushort 	bytes_per_sector; // 11-12
	uchar 	sectors_per_cluster; // 13
	ushort 	reserved_sectors; // 14-15
	uchar 	num_fat_copy; // 16
	ushort 	num_root_dir; // 17-18
	ushort	num_sectors_in_filesys; //19-20
	uchar 	media_type; // 21
	ushort	sectors_per_fat; // 22-23
	ushort	sectors_per_track; // 24-25
	ushort	num_heads; // 26-27
	
	// Fat32
	uint	num_hidden_sectors; // 28-31
	uint 	filesys_sectors; // 32-35
	uint	fat32_sectors_per_fat;  // 36-39
	ushort	mirror_flag; // 40-41
	ushort	filesys_version; // 42-43
	uint	first_cluster_of_root_dir; // 44-47
	ushort	filesys_info_sec_num_in_fat32; // 48-49
	ushort	boot_sec_backup_loc; // 50-51
	uchar 	reserved[12]; // 52-63
	uchar	drive_num; // 64
	uchar	reserved_2; // 65
	uchar	extend_sign; //66
	uint	serial_number; // 67-70
	uchar	label[11]; // 71-81
	uchar	file_sys[8]; // 82-89
} __attribute__((packed));

uint get_cluster_size(struct oem_block *oem) {
	return oem->sectors_per_cluster * oem->bytes_per_sector;
}

void read_cluster(struct oem_block * oem, partition_entry *pentry,  int cluster, char **buffer, FILE *fp) {	
	// uint fat_begin = pentry->lba_first_sector + oem->reserved_sectors * 512;
	// uint clus_begin = fat_begin + oem->num_fat_copy * oem->fat32_sectors_per_fat * 512;
	uint root_begin = pentry->lba_first_sector + (oem->reserved_sectors + oem->num_fat_copy * oem->fat32_sectors_per_fat) * 512;
	
	fseek(fp, root_begin + (cluster - 2) * get_cluster_size(oem), SEEK_SET);
	fread(*buffer, get_cluster_size(oem), 1, fp);
}

void read_fat(oem_block *oem, partition_entry *pentry, char **buffer, FILE *fp) {
	uint fat_begin = pentry->lba_first_sector + oem->reserved_sectors * 512;
	fseek(fp, fat_begin, SEEK_SET);	
	fread(*buffer, oem->fat32_sectors_per_fat * 512, 1, fp);
}

struct fat_info {
	uint partition_lba_begin;
	
};

void read_partition(FILE *fp, uint lba, partition_entry *pentry) {
	printf("Sizeof struct oem_block: %d\n", sizeof(oem_block));
	printf("Partition begin from LBA: %ld\n", lba);
	fseek(fp, lba, SEEK_SET);
	
	oem_block oem;
	fread(&oem, sizeof(oem), 1, fp);
	
	char oem_name[9];
	memcpy(oem_name, oem.oem_name, 8);
	oem_name[8] = 0;
	
	printf("--- OEM name: %s\n", oem_name);
	printf("--- bytes per sector: %d\n", oem.bytes_per_sector);
	printf("--- sectors per cluster: %d\n", oem.sectors_per_cluster);
	printf("--- reserved_sectors: %d\n", oem.reserved_sectors);
	printf("--- num_fat_copy: %d\n", oem.num_fat_copy);
	
	// FAT 32
	printf("--- FAT32 stuffs ---\n");
	printf("--- fat32_sectors_per_fat: %d\n", oem.fat32_sectors_per_fat);
	printf("--- first_cluster_of_root_dir: %d\n", oem.first_cluster_of_root_dir);
	
	char buffer[12];
	memcpy(buffer, oem.label, 11);
	buffer[11] = 0;
	printf("--- label: %s\n", buffer);
	
	memcpy(buffer, oem.file_sys, 8);
	buffer[8] = 0;
	printf("--- file_sys: %s\n", buffer);
	
	if (lba == 2048) { // First drive
		
		char *buffer = new char[get_cluster_size(&oem)];
		char *fat = new char[oem.fat32_sectors_per_fat * oem.bytes_per_sector];
		
		read_fat(&oem, pentry, &fat, fp);
		read_cluster(&oem, pentry, oem.first_cluster_of_root_dir, &buffer, fp);
		printf("%s\n", buffer);
		
		delete [] buffer;
		delete[] fat;
	}
}

int main(int argc, char *argv[]) {
	printf("Sizeof struct partition_entry: %d\n", sizeof(partition_entry));

	partition_entry entries[4];

	FILE *fp = fopen("disk.img", "rb");
	if (fp) {
		fseek(fp, 446, SEEK_SET);
		fread(entries, sizeof(entries), 1, fp);

		for(int i=0; i<4; ++i) {
			printf("Partition %d:\n", i+1);
			printf("--- status: 0x%x\n", entries[i].status);
			

			ushort cyld = get_cylinder(&entries[i].start);
			ushort head = entries[i].start.head;
			ushort sect = entries[i].start.sector;
			printf("--- begin CHS: (%d, %d, %d)\n", cyld, head, sect);
			
			printf("--- type: 0x%x\n", entries[i].type);
			
			cyld = get_cylinder(&entries[i].end);
			head = entries[i].end.head;
			sect = entries[i].end.sector;
			
			printf("--- end CHS: (%d, %d, %d)\n", cyld, head, sect);
			
			printf("--- LBA of first sector: %d\n", entries[i].lba_first_sector);
			printf("--- Num of sector: %d\n", entries[i].num_of_sectors);
		}
		
		for(int i=0; i<4; i++) {
			if (entries[i].lba_first_sector > 0)
				read_partition(fp, entries[i].lba_first_sector, &entries[i]);
		}

		fclose(fp);
	} else {
		printf("Can\'t open disk.img file\n");
	}

	return 0;
}
