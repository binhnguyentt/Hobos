#include <iostream>
#include <list>
#include <stdio.h>
#include <string.h>

using namespace std;

typedef unsigned char 	uchar;
typedef unsigned short 	ushort;
typedef unsigned int 	uint;

typedef uint dword_t;
typedef ushort word_t;
typedef uchar byte_t;

struct fat32_bpb {
    word_t jmp;
    byte_t nop;
    byte_t oem_name[8];
    word_t bytes_per_sec;
    byte_t sectors_per_cluster;
    word_t reserved_sectors;
    byte_t number_of_fat;
    word_t old_max_root_entry;
    word_t old_sectors_smaller_than_32mib;
    byte_t media_descriptor;
    word_t old_sector_per_fat;
    word_t sectors_per_track;
    word_t number_of_heads;
    dword_t num_hidden_sectors;
    dword_t num_sectors;
    dword_t num_sectors_per_fat;
    word_t flag;
    word_t fat32_drive;
    dword_t cluster_start_root_dir;
    word_t sector_filesys_info;
    word_t sector_backupboot;
    byte_t reserved_2[12];
    byte_t drive_number;
    byte_t unused;
    byte_t extended_sig;
    dword_t serial;
    byte_t label[11];
    byte_t fat_name[8];
} __attribute__((packed));

struct attrib {
    byte_t readonly:1;
    byte_t hidden:1;
    byte_t system:1;
    byte_t volume_label:1;
    byte_t sub_dir:1;
    byte_t archive:1;
    byte_t device:1;
    byte_t reserved:1;
} __attribute__((packed));

struct seq_number {
    byte_t number:5;
    byte_t zero: 1;
    byte_t last_logical: 1;
} __attribute__((packed));

struct dir_entry {
    union {
        byte_t sfn[11];
        struct {
            seq_number seq_num;
            word_t name[5];
        } __attribute__((packed)) lfn;
    } first;

    union {
        attrib attribute; // alway 0x0F for LFN
        byte_t attr_val;
    } attribute;

    byte_t type; // alway 0x00 for LFN
    byte_t checksum;

    union {
        struct {
            word_t unsed[3];
            word_t cluster_high;
            word_t unsed_2[2];
            word_t cluster_low;
            dword_t size;
        } __attribute__((packed)) sfn;

        struct {
            word_t name2[6];
            word_t cluster;
            word_t name3[2];
        } __attribute__((packed)) lfn;
    } second;
} __attribute__((packed));

enum ITEM_TYPE {
    TYPE_FILE,
    TYPE_DIR
};

struct item_info {
    char *name;
    ITEM_TYPE type;
    dword_t size;
    dword_t cluster;
};

void fat32_info(fat32_bpb* bpb) {
    char buffer[20];

    memcpy(buffer, bpb->oem_name, 8);
    buffer[8] = 0;

    printf("OEM name: \t\t%s\n", buffer);
    printf("bytes_per_sector: \t%d\n", bpb->bytes_per_sec);
    printf("sectors_per_cluster: \t%d\n", bpb->sectors_per_cluster);
    printf("reserved_sectors: \t%d\n", bpb->reserved_sectors);
    printf("number_of_fat: \t\t%d\n", bpb->number_of_fat);
    printf("num_sectors_per_fat: \t%d\n", bpb->num_sectors_per_fat);
    printf("cluster_start_root_dir: %d\n", bpb->cluster_start_root_dir);

    memcpy(buffer, bpb->label, 11);
    buffer[11] = 0;
    printf("label: \t\t\t%s\n", buffer);

    memcpy(buffer, bpb->fat_name, 8);
    buffer[8] = 0;
    printf("fat_name: \t\t%s\n", buffer);
}

uint get_fat_begin(fat32_bpb* bpb, uint start_lba = 0) {
    return bpb->reserved_sectors * bpb->bytes_per_sec;
}

uint get_root_dir_begin(fat32_bpb* bpb) {
    return (bpb->reserved_sectors
            + bpb->num_sectors_per_fat * bpb->number_of_fat
            + (bpb->cluster_start_root_dir - 2) * bpb->sectors_per_cluster) * bpb->bytes_per_sec;
}

uint get_cluster_size(int num, fat32_bpb *bpb) {
    return bpb->sectors_per_cluster * bpb->bytes_per_sec * num;
}

uint get_cluster_lba(int num, fat32_bpb *bpb) {
    return get_root_dir_begin(bpb) + get_cluster_size(num - 2, bpb);
}

int get_cluster_from_lba(uint lba, fat32_bpb *bpb) {
    lba = lba - get_root_dir_begin(bpb);
    uint cluster = lba / get_cluster_size(1, bpb);
    return cluster + 2;
}

int convert_utf16_to_ansi(char *ansi, word_t *utf16) {
    for(int i=0; true; i++) {
        ansi[i] = utf16[i];
        if (ansi[i] == 0) return i;
    }

    return -1;
}

int strlen_w(word_t *utf16, int max = -1) {
    for(int i=0; true; ++i) {
        if (utf16[i] == 0 || utf16[i] == 0xffff) return i;
        if (max > -1 && i >= max) return max;
    }

    return -1;
}

list<item_info> list_dir(dword_t lba, FILE *fp, int cluster_size) {
    list<item_info> lst;

    char *cluster = new char[cluster_size];
    fseek(fp, lba, SEEK_SET);
    fread(cluster, cluster_size, 1, fp);

    dir_entry * dir = (dir_entry *) cluster;
    char buffer[512];
    word_t wbuff[256];
    word_t * buff_ptr;

    wbuff[255] = 0;
    while (dir->first.sfn[0] != 0) {
        if (dir->attribute.attr_val == 0xF && dir->second.sfn.cluster_low == 0x0) {
            // LFN
            if(dir->first.lfn.seq_num.last_logical == 1) {
                buff_ptr = &wbuff[255];
            }

            if (dir->first.lfn.seq_num.number == 1) {
                int len = strlen_w(dir->second.lfn.name3, 2);
                if (len > 0) {
                    buff_ptr -= len;
                    memcpy(buff_ptr, dir->second.lfn.name3, len*2);
                }

                len = strlen_w(dir->second.lfn.name2, 6);
                if (len > 0) {
                    buff_ptr -= len;
                    memcpy(buff_ptr, dir->second.lfn.name2, len * 2);
                }

                len = strlen_w(dir->first.lfn.name, 5);
                if (len > 0) {
                    buff_ptr -= len;
                    memcpy(buff_ptr, dir->first.lfn.name, len * 2);
                }
            } else {
                buff_ptr -= 2;
                memcpy(buff_ptr, dir->second.lfn.name3, 4);

                buff_ptr -= 6;
                memcpy(buff_ptr, dir->second.lfn.name2, 12);

                buff_ptr -= 5;
                memcpy(buff_ptr, dir->first.lfn.name, 10);
            }
        } else {
            item_info item;

            int len = strlen_w(buff_ptr);
            item.name = new char[len + 1];
            item.name[len] = 0;
            convert_utf16_to_ansi(item.name, buff_ptr);

            if (dir->attribute.attribute.sub_dir == 1) {
                item.type = TYPE_DIR;
            } else {
                item.type = TYPE_FILE;
            }

            item.size = dir->second.sfn.size;
            item.cluster = ((dword_t) dir->second.sfn.cluster_high) | dir->second.sfn.cluster_low;
            lst.push_back(item);
        }

        dir ++;
    }

    delete[] cluster;
    return lst;
}

bool read_file(int cluster, dword_t size, char **buffer, FILE *fp, char *fat, fat32_bpb *bpb) {
    cout << "----read_file----" << endl;
    int one_clus_size = get_cluster_size(1, bpb);
    dword_t *fat_table = (dword_t *) fat;

    dword_t pending = size;
    char *buff = *buffer;

    dword_t cur_cluster = cluster, lba;
    while (pending > 0) {
        lba = get_cluster_lba(cur_cluster, bpb);
        fseek(fp, lba, SEEK_SET);

        cout << "cluster: " << cur_cluster << ", lba: " << lba << endl;
        if (pending >= one_clus_size) {
            cout << "read one cluster ..." << endl;
            fread(buff, one_clus_size, 1, fp);
            pending -= one_clus_size;
            buff += one_clus_size;
        } else {
            cout << "read piece of " << pending << " bytes" << endl;
            fread(buff, pending, 1, fp);
            pending = 0;
        }

        cout << "next cluster is: 0x";
        cur_cluster = fat_table[cur_cluster];
        cout << hex << cur_cluster << endl;
        if (cur_cluster == 0x0fffffff) {
            cout << "got end of file, exitting..." << endl;
            break;
        }
    }

    return true;
}

void read_dir(dword_t lba, FILE *fp, char *fat, fat32_bpb* bpb) {
    cout << "----read_dir----" << endl;
    cout << "Sizeof struct dir_entry: " << sizeof(struct dir_entry) << "bytes" << endl;
    cout << "LBA of dir: " << lba << endl;


    list<item_info> items = list_dir(lba, fp, get_cluster_size(1, bpb));
    for(list<item_info>::iterator i=items.begin(); i!=items.end(); i++) {
        cout << ((i->type == TYPE_DIR) ? "D":"F") << "|" << i->cluster << ": "
                << i->name << " (" << i->size << ")" << endl;

        delete[] i->name;
    }
}

int main(int argc, char *argv[]) {
	cout << "Sizeof(fat32_bpb): " << sizeof(fat32_bpb) << endl;
	
    FILE *fp = fopen("/home/nguyenbinh/Desktop/myos/fat32/fat32.img", "rb");
    if (fp) {
        struct fat32_bpb bpb;
        char* fat;

        // Read bpb
        fread(&bpb, sizeof(bpb), 1, fp);

        // Read fat table
        fat = new char[bpb.num_sectors_per_fat * bpb.bytes_per_sec];
        fseek(fp, get_fat_begin(&bpb), SEEK_SET);
        fread(fat, bpb.num_sectors_per_fat * bpb.bytes_per_sec, 1, fp);

        fat32_info(&bpb);
        read_dir(get_root_dir_begin(&bpb), fp, fat, &bpb);

        /* char *buffer = new char[46415230];
        read_file(8, 46415230, &buffer, fp, fat, &bpb);

        FILE *fppdf = fopen("file.pdf", "wb");
        if (fppdf) {
            fwrite(buffer, 46415230, 1, fppdf);
            fclose(fppdf);
        } else {
            cout << "failed to create file.pdf" << endl;
        }

        delete[] buffer; */

        delete[] fat;
        fclose(fp);
    } else {
        printf("Ca\'nt open fat32.img for reading!!!");
    }
}
