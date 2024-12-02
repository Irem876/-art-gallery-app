import List "mo:base/List";
import Option "mo:base/Option";
import Trie "mo:base/Trie";
import Nat32 "mo:base/Nat32";

actor SanatGalerisi {
  public type EserId = Nat32;

  public type Eser = {
    title: Text;
    artist: Text;
    category: { #Resim; #Heykel; #DijitalSanat; #Fotograf };
    creationYear: Nat32;
    isExhibited: Bool;
    exhibitionHistory: List.List<Text>; // Sergi detayları (tarih, yer)
  };

  private stable var nextEserId: EserId = 0;
  private stable var eserler: Trie.Trie<EserId, Eser> = Trie.empty();

  // Sanat Eseri Ekleme
  public func eserEkle(eser: Eser) : async EserId {
    let eserId = nextEserId;
    nextEserId += 1;
    eserler := Trie.replace(
      eserler,
      key(eserId),
      Nat32.equal,
      ?eser
    ).0;
    return eserId;
  };

  // Sanat Eseri Görüntüleme
  public query func eserOku(eserId: EserId) : async ?Eser {
    return Trie.find(eserler, key(eserId), Nat32.equal);
  };

  // Sanat Eseri Güncelleme
  public func eserGuncelle(eserId: EserId, eser: Eser) : async Bool {
    let mevcut = Option.isSome(Trie.find(eserler, key(eserId), Nat32.equal));
    if (mevcut) {
      eserler := Trie.replace(eserler, key(eserId), Nat32.equal, ?eser).0;
    };
    return mevcut;
  };

  // Sanat Eseri Silme
  public func eserSil(eserId: EserId) : async Bool {
    let mevcut = Option.isSome(Trie.find(eserler, key(eserId), Nat32.equal));
    if (mevcut) {
      eserler := Trie.replace(eserler, key(eserId), Nat32.equal, null).0;
    };
    return mevcut;
  };

  // Kategoriye Göre Listeleme
  public query func kategoriListele(kategori: { #Resim; #Heykel; #DijitalSanat; #Fotograf }) : async List.List<Eser> {
    let allEserler = Trie.toList(eserler);
    return List.filter(allEserler, func (entry) {
      return entry.value.category == kategori;
    });
  };

  // Sergi Raporu
  public query func sergiRaporu(artist: Text) : async Nat {
    let allEserler = Trie.toList(eserler);
    return List.foldLeft(allEserler, 0, func (toplam, entry) {
      let eser = entry.value;
      return if (eser.artist == artist and eser.isExhibited) {
        toplam + 1
      } else {
        toplam
      };
    });
  };

  // Sergi Ekleme
  public func sergiEkle(eserId: EserId, sergiDetayi: Text) : async Bool {
    switch (Trie.find(eserler, key(eserId), Nat32.equal)) {
      case (?eser) {
        let guncelEser = {
          eser with
          isExhibited = true;
          exhibitionHistory = List.append(eser.exhibitionHistory, List.cons(sergiDetayi, List.nil<Text>()));
        };
        eserler := Trie.replace(eserler, key(eserId), Nat32.equal, ?guncelEser).0;
        return true;
      };
      case (null) {
        return false; // Eser bulunamadı
      };
    }
  };

  // Key Fonksiyonu
  private func key(x: EserId) : Trie.Key<EserId> {
    return {hash = x; key = x};
  };
};
